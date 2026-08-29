{ ... }:
{
  keymaps = [
    {
      mode = "t";
      key = "<leader>cd";
      action.__raw = ''
        function()
          nixvim_project_lsp.sync_terminal_cwd()
        end
      '';
      options = {
        desc = "Sync terminal pwd to Neovim cwd";
        silent = true;
      };
    }
    {
      mode = "t";
      key = "<leader>ce";
      action.__raw = ''
        function()
          nixvim_project_lsp.use_terminal_project()
        end
      '';
      options = {
        desc = "Load project dev shell for LSPs";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>ce";
      action = "<cmd>NixDevelopLsp<CR>";
      options = {
        desc = "Load project dev shell for LSPs";
        silent = true;
      };
    }
  ];

  extraConfigLua = ''
    do
      local project_lsp = {}
      local original_configs = {}
      local wrapped_commands = {}
      local selected_project
      local activation_generation = 0
      local filetype_retry_scheduled = false
      local nix = vim.fn.exepath("nix")
      local editor_path = vim.env.PATH or ""

      local transient_environment = {
        NIX_BUILD_TOP = true,
        NVIM = true,
        NVIM_LISTEN_ADDRESS = true,
        OLDPWD = true,
        PWD = true,
        SHLVL = true,
        TEMP = true,
        TEMPDIR = true,
        TMP = true,
        TMPDIR = true,
        VIM = true,
        VIMRUNTIME = true,
        ["_"] = true,
      }

      local function notify_error(message)
        vim.notify(message, vim.log.levels.ERROR)
      end

      local function normalize(path)
        local realpath = vim.uv.fs_realpath(path)
        return vim.fs.normalize(realpath or path)
      end

      local function contains_path(parent, child)
        if not parent or not child then
          return false
        end

        parent = normalize(parent)
        child = normalize(child)
        return child == parent
          or child:sub(1, #parent + 1) == parent .. "/"
      end

      local function paths_overlap(left, right)
        if not left or not right then
          return true
        end

        return contains_path(left, right) or contains_path(right, left)
      end

      local function merge_paths(project_path, build_top)
        local result = {}
        local seen = {}

        for _, path in ipairs({ project_path or "", editor_path }) do
          for entry in path:gmatch("[^:]+") do
            if not seen[entry]
              and not contains_path(build_top, entry)
            then
              seen[entry] = true
              result[#result + 1] = entry
            end
          end
        end

        return table.concat(result, ":")
      end

      local function parse_environment(stdout)
        -- shellHook output may precede the sentinel. It must not become part
        -- of an LSP's stdout because that stream is reserved for JSON-RPC.
        local sentinel = stdout:find("\0", 1, true)
        if not sentinel then
          return nil, "nix develop returned no environment"
        end

        local environment = {}
        for entry in stdout:sub(sentinel + 1):gmatch("([^%z]+)") do
          local separator = entry:find("=", 1, true)
          if separator then
            environment[entry:sub(1, separator - 1)] = entry:sub(separator + 1)
          end
        end

        local build_top = environment.NIX_BUILD_TOP
        environment.PATH = merge_paths(environment.PATH, build_top)

        for name, value in pairs(environment) do
          if transient_environment[name]
            or (name ~= "PATH"
              and build_top
              and value:find(build_top, 1, true))
          then
            environment[name] = nil
          end
        end

        return environment
      end

      local function concise_output(output)
        output = vim.trim(output or "")
        if #output > 1000 then
          return output:sub(1, 1000) .. "…"
        end
        return output
      end

      local function executable_in_path(executable, path)
        if executable:find("/", 1, true) then
          return executable
        end

        for directory in (path or ""):gmatch("[^:]+") do
          local candidate = directory .. "/" .. executable
          if vim.fn.executable(candidate) == 1 then
            return candidate
          end
        end

        return executable
      end

      local function project_command(original, environment)
        local command = vim.deepcopy(original.cmd)
        command[1] = executable_in_path(command[1], environment.PATH)
        return command
      end

      local function start_command(command, dispatchers, config, cwd, environment)
        return vim.lsp.rpc.start(command, dispatchers, {
          cwd = cwd,
          detached = config.detached,
          env = environment,
        })
      end

      local function make_command(config_name)
        return function(dispatchers, config)
          local original = original_configs[config_name]
          local project = selected_project

          if project and paths_overlap(project.root, config.root_dir) then
            local environment = vim.tbl_extend(
              "force",
              {},
              project.environment,
              original.cmd_env or {}
            )
            local cwd = original.cmd_cwd or config.root_dir or project.root
            return start_command(
              project_command(original, environment),
              dispatchers,
              config,
              cwd,
              environment
            )
          end

          return start_command(
            original.cmd,
            dispatchers,
            config,
            original.cmd_cwd,
            original.cmd_env
          )
        end
      end

      local function wrap_enabled_configs()
        local enabled_names = {}
        local changed = false

        for _, config in ipairs(vim.lsp.get_configs({ enabled = true })) do
          if original_configs[config.name] == nil then
            if type(config.cmd) == "table" then
              original_configs[config.name] = {
                cmd = vim.deepcopy(config.cmd),
                cmd_cwd = config.cmd_cwd,
                cmd_env = vim.deepcopy(config.cmd_env),
              }
            end
          end

          if original_configs[config.name] then
            local command = wrapped_commands[config.name]
            if not command then
              command = make_command(config.name)
              wrapped_commands[config.name] = command
            end

            enabled_names[#enabled_names + 1] = config.name
            if config.cmd ~= command then
              vim.lsp.config(config.name, { cmd = command })
              changed = true
            end
          end
        end

        return enabled_names, changed
      end

      local function activate_project(project)
        selected_project = project
        vim.g.nix_develop_lsp_root = project.root
        vim.cmd("cd " .. vim.fn.fnameescape(project.root))

        local clients = vim.lsp.get_clients()
        local enabled_names = wrap_enabled_configs()
        local restart_names = {}

        for _, client in ipairs(clients) do
          local command = wrapped_commands[client.name]
          if command and paths_overlap(project.root, client.root_dir) then
            client.config.cmd = command
            restart_names[client.name] = true
          end
        end

        -- Re-run activation for every loaded file buffer. This retries
        -- servers which previously failed because their executable or their
        -- compiler was unavailable outside the project's development shell.
        if #enabled_names > 0 then
          vim.lsp.enable(enabled_names)
        end

        local restarted = 0
        for name in pairs(restart_names) do
          vim.api.nvim_cmd({
            cmd = "lsp",
            args = { "restart", name },
          }, {})
          restarted = restarted + 1
        end

        local suffix = restarted == 1
            and "; restarted 1 LSP client"
          or string.format("; restarted %d LSP clients", restarted)
        vim.notify(
          "LSP development shell: " .. project.root .. suffix,
          vim.log.levels.INFO
        )
      end

      local function find_flake_root(directory)
        local flake = vim.fs.find("flake.nix", {
          path = directory,
          upward = true,
        })[1]

        return flake and normalize(vim.fs.dirname(flake)) or nil
      end

      local function load_environment(project_root)
        activation_generation = activation_generation + 1
        local generation = activation_generation

        vim.notify(
          "Loading LSP development shell: " .. project_root,
          vim.log.levels.INFO
        )

        vim.system({
          nix,
          "develop",
          "--command",
          "sh",
          "-c",
          [[printf '\0'; exec env -0]],
        }, {
          cwd = project_root,
        }, function(result)
          if generation ~= activation_generation then
            return
          end

          if result.code ~= 0 then
            local detail = concise_output(result.stderr)
            if detail == "" then
              detail = concise_output(result.stdout)
            end

            vim.schedule(function()
              notify_error(
                "Could not load nix develop for " .. project_root
                  .. (detail ~= "" and ":\n" .. detail or "")
              )
            end)
            return
          end

          local environment, parse_error = parse_environment(
            result.stdout or ""
          )
          vim.schedule(function()
            if generation ~= activation_generation then
              return
            end

            if not environment then
              notify_error(parse_error)
              return
            end

            activate_project({
              root = project_root,
              environment = environment,
            })
          end)
        end)
      end

      function project_lsp.use_directory(directory)
        directory = normalize(vim.fs.abspath(directory))
        if vim.fn.isdirectory(directory) == 0 then
          notify_error("Not a directory: " .. directory)
          return
        end

        local project_root = find_flake_root(directory)
        if not project_root then
          notify_error("No flake.nix found above " .. directory)
          return
        end

        if nix == "" then
          notify_error("The nix executable is not available")
          return
        end

        load_environment(project_root)
      end

      local function terminal_cwd(callback)
        local pid = vim.fn.jobpid(vim.bo.channel)

        local function finish(cwd)
          if not cwd or vim.fn.isdirectory(cwd) == 0 then
            notify_error("Could not determine the terminal working directory")
            return
          end

          callback(normalize(cwd))
        end

        if vim.uv.os_uname().sysname == "Linux" then
          finish(vim.uv.fs_readlink("/proc/" .. pid .. "/cwd"))
        elseif vim.fn.executable("lsof") == 1 then
          vim.system(
            { "lsof", "-a", "-p", tostring(pid), "-d", "cwd", "-Fn" },
            { text = true },
            function(result)
              local cwd
              if result.code == 0 then
                local stdout = result.stdout or ""
                cwd = stdout:match("\nn([^\r\n]+)")
                  or stdout:match("^n([^\r\n]+)")
              end

              vim.schedule(function()
                finish(cwd)
              end)
            end
          )
        else
          finish(nil)
        end
      end

      function project_lsp.sync_terminal_cwd()
        terminal_cwd(function(cwd)
          vim.cmd("cd " .. vim.fn.fnameescape(cwd))
          vim.notify("Neovim cwd: " .. cwd, vim.log.levels.INFO)
        end)
      end

      function project_lsp.use_terminal_project()
        terminal_cwd(project_lsp.use_directory)
      end

      vim.api.nvim_create_user_command("NixDevelopLsp", function(args)
        local directory = args.args ~= "" and args.args or vim.fn.getcwd()
        project_lsp.use_directory(directory)
      end, {
        nargs = "?",
        complete = "dir",
        desc = "Load a project's Nix development shell for its LSP servers",
      })

      -- Install wrappers before native LSP FileType activation whenever the
      -- configs are already loaded. The scheduled retry also covers configs
      -- which a lazy plugin loads during the same FileType event.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup(
          "nixvim_project_lsp",
          { clear = true }
        ),
        callback = function()
          if not selected_project then
            return
          end

          wrap_enabled_configs()
          if filetype_retry_scheduled then
            return
          end

          filetype_retry_scheduled = true
          vim.schedule(function()
            filetype_retry_scheduled = false
            if not selected_project then
              return
            end

            local enabled_names, changed = wrap_enabled_configs()
            if changed and #enabled_names > 0 then
              vim.lsp.enable(enabled_names)
            end
          end)
        end,
      })

      _G.nixvim_project_lsp = project_lsp
    end
  '';
}
