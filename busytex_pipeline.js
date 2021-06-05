//TODO: work with only files paths (without dir paths)
//TODO: what happens if creating another pipeline (waiting data error?)
//TODO: TEXMFLOG?
//TODO: put texlive into /opt/texlive/2020 or ~/.texlive2020?
//TODO: configure fontconfig to use /etc/fonts
//TODO: move latex.fmt to /texlive

class BusytexPipeline
{
    static VerboseSilent = 'silent';
    static VerboseInfo = 'info';
    static VerboseDebug = 'debug';

    //FIXME begin: have to do static to execute LZ4 data packages: https://github.com/emscripten-core/emscripten/issues/12347
    static preRun = [];
    static calledRun = false;
    static data_packages = [];
    static locateFile(remote_package_name) 
    {
        return BusytexPipeline.data_packages.map(data_package_js => data_package_js.replace('.js', '.data')).find(data_file => data_file.endsWith(remote_package_name));
    }
    //FIXME end

    static ScriptLoaderDocument(src)
    {
        return new Promise((resolve, reject) =>
        {
            let s = self.document.createElement('script');
            s.src = src;
            s.onload = resolve;
            s.onerror = reject;
            self.document.head.appendChild(s);
        });
    }

    static ScriptLoaderRequire(src)
    {
        return new Promise(resolve => self.require([src], resolve));
    }

    static ScriptLoaderWorker(src)
    {
        return Promise.resolve(self.importScripts(src));
    }

    load_package(data_package_js)
    {
        if(data_package_js in this.data_package_promises)
            return this.data_package_promises[data_package_js];

        BusytexPipeline.calledRun = false;
        const promise = this.script_loader(data_package_js);
        BusytexPipeline.data_packages.push(data_package_js);
        this.data_package_promises[data_package_js] = promise;
        return promise;
    }

    constructor(busytex_js, busytex_wasm, data_packages_js, texmf_local, print, preload, script_loader)
    {
        this.print = print;
        this.preload = preload;
        this.script_loader = script_loader;
        
        this.wasm_module_promise = fetch(busytex_wasm).then(WebAssembly.compileStreaming);
        this.em_module_promise = this.script_loader(busytex_js);
        
        BusytexPipeline.data_packages = [];
        this.data_package_promises = {};

        for(const data_package_js of data_packages_js)
            this.load_package(data_package_js); 
        
        this.ansi_reset_sequence = '\x1bc';
        
        this.project_dir = '/home/web_user/project_dir';
        this.bin_busytex = '/bin/busytex';
        this.fmt_latex = '/xelatex.fmt';
        //this.dir_texmfdist = ['/texlive', '/texmf', ...texmf_local].map(texmf => (texmf.startsWith('/') ? '' : (this.project_dir + '/')) + texmf + '/texmf-dist').join(':');
        this.dir_texmfdist = ['/texlive', '/texmf', ...texmf_local].map(texmf => texmf + '/texmf-dist').join(':');
        this.dir_texmfvar = '/texlive/texmf-dist/texmf-var';
        this.dir_cnf = '/texlive/texmf-dist/web2c';
        this.dir_fontconfig = '/etc/fonts';

        this.verbose_args = 
        {
            [BusytexPipeline.VerboseSilent] : {
                xetex : [],
                bibtex8 : [],
                xdvipdfmx : []
            },
            [BusytexPipeline.VerboseInfo] : {
                xetex: ['-kpathsea-debug', '32'],
                bibtex8 : ['--debug', 'search'],
                xdvipdfmx : ['-v', '--kpathsea-debug', '32'],
            },
            [BusytexPipeline.VerboseDebug] : {
                xetex : ['-kpathsea-debug', '63', '-recorder'],
                bibtex8 : ['--debug', 'all'],
                xdvipdfmx : ['-vv', '--kpathsea-debug', '63'],
            },
        };

        this.mem_header_size = 2 ** 25;
        this.env = {TEXMFDIST : this.dir_texmfdist, TEXMFVAR : this.dir_texmfvar, TEXMFCNF : this.dir_cnf, FONTCONFIG_PATH : this.dir_fontconfig};
        this.Module = this.reload_module_if_needed(this.preload !== false, this.env, this.project_dir, data_packages_js);
    }

    terminate()
    {
        this.Module = null;
    }

    async reload_module_if_needed(cond, env, project_dir, data_packages_js)
    {
        if(cond)
        {
            console.log('RELOADING', data_packages_js);
            return this.reload_module(env, project_dir, data_packages_js);
        }
        else if(this.Module)
        {
            const Module = await this.Module;
            const enabled_packages = Module.data_packages_js;
            const new_data_packages_js = data_packages_js.filter(data_package_js => !enabled_packages.includes(data_package_js));
           
            if(new_data_packages_js.length > 0)
                return this.reload_module(env, project_dir, Array.from(enabled_packages_js).concat(Array.from(new_data_packages_js)));
            return Module;

            /*console.log('LOADINGPACKAGES', new_data_packages_js);
            Module.calledRun = false;
            const dependencies_fullfilled = new Promise(resolve => (Module.run = resolve));

            await Promise.all(new_data_packages_js.map(data_package_js => this.load_package(data_package_js)));
            console.log('PRERUNNING');
            Module.pre_run_packages(Module)();
            
            enabled_packages.push(...new_data_packages_js);
            
            await dependencies_fullfilled;
            return Module;*/
        }
    }

    async reload_module(env, project_dir, data_packages_js = [])
    {
        const data_packages_js_promise = data_packages_js.map(data_package_js => this.load_package(data_package_js));
        const [wasm_module, em_module] = await Promise.all([this.wasm_module_promise, this.em_module_promise, ...data_packages_js_promise]);
        const {print, init_env} = this;
        
        const pre_run_packages = Module => () =>
        {
            Object.setPrototypeOf(BusytexPipeline, Module);
            console.log('pre_run_packages', BusytexPipeline.preRun);

            for(const preRun of BusytexPipeline.preRun)
            {
                if(Module.preRuns.includes(preRun))
                    continue;

                preRun();
                Module.preRuns.push(preRun);
            }
        }
        
        const Module =
        {
            thisProgram : this.bin_busytex,
            noInitialRun : true,
            totalDependencies: 0,
            prefix : '',
            preRuns : [],
            data_packages_js : data_packages_js,
            pre_run_packages : pre_run_packages,
            
            preRun : [() => { Object.assign(Module.ENV, env); Module.FS.mkdir(project_dir); self.LZ4 = Module.LZ4; }, () => pre_run_packages(Module)()],

            instantiateWasm(imports, successCallback)
            {
                WebAssembly.instantiate(wasm_module, imports).then(successCallback);
            },
            
            print(text) 
            {
                if(verbose == BusytexVerboseSilent)
                    return;

                Module.setStatus(Module.prefix + ' | stdout: ' + (arguments.length > 1 ?  Array.prototype.slice.call(arguments).join(' ') : text));
            },

            printErr(text)
            {
                Module.setStatus(Module.prefix + ' | stderr: ' + (arguments.length > 1 ?  Array.prototype.slice.call(arguments).join(' ') : text));
            },
            
            setPrefix(text)
            {
                this.prefix = text;
            },
            
            setStatus(text)
            {
                print(Module.thisProgram + ': ' + text);
            },
            
            monitorRunDependencies(left)
            {
                this.totalDependencies = Math.max(this.totalDependencies, left);
                Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
            },
        };
       
        const initialized_module = await busytex(Module);
        this.print(`INITIALIZED ${initialized_module.data_packages_js}`);
        
        console.assert(this.mem_header_size % 4 == 0 && initialized_module.HEAP32.slice(this.mem_header_size / 4).every(x => x == 0));
        
        return initialized_module;
    }

    async compile(files, main_tex_path, bibtex, verbose, driver, data_packages_js = [])
    {
        const NOCLEANUP_callMain = (Module, args) =>
        {
            Module.setPrefix(args[0]);
            const main = Module['_main'], fflush = Module['_fflush'], NULL = 0;
            const argc = args.length+1;
            const argv = Module.stackAlloc((argc + 1) * 4);
            Module.HEAP32[argv >> 2] = Module.allocateUTF8OnStack(Module.thisProgram);
            for (let i = 1; i < argc; i++) 
                Module.HEAP32[(argv >> 2) + i] = Module.allocateUTF8OnStack(args[i - 1]);
            Module.HEAP32[(argv >> 2) + argc] = NULL;

            try
            {
                main(argc, argv);
            }
            catch(e)
            {
                fflush(NULL);
                this.print('callMain: ' + e.message);
                return e.status;
            }
            
            return 0;
        }
        
        this.print(this.ansi_reset_sequence);
        this.print(`New compilation started: [${main_tex_path}]`);
        
        console.assert(driver == 'xetex_bibtex8_dvipdfmx'); // TODO: support 'xetex_dvidpfmx', 'pdftex_bibtex8', 'luatex_bibtex8'
        
        this.Module = this.reload_module_if_needed(this.Module == null, this.env, this.project_dir, data_packages_js);
        
        console.log('MODULE', this.Module);

        const Module = await this.Module;
        this.print(`Module.data_packages ${Module.data_packages_js} data_packages ${data_packages_js} FIN`);
        const [FS, PATH] = [Module.FS, Module.PATH];

        const source_name = main_tex_path.slice(1 + main_tex_path.lastIndexOf('/'));
        const tex_path = source_name;
        const [xdv_path, pdf_path, log_path, aux_path] = ['.xdv', '.pdf', '.log', '.aux'].map(ext => tex_path.replace('.tex', ext));
        
        const xetex = ['xetex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt_latex, tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).xetex);
        const bibtex8 = ['bibtex8', '--8bit', aux_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).bibtex8);
        const xdvipdfmx = ['xdvipdfmx', '-o', pdf_path, xdv_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).xdvipdfmx);

        FS.mount(FS.filesystems.MEMFS, {}, this.project_dir);
        let dirs = new Set(['/', this.project_dir]);

        const mkdir_p = dirpath =>
        {
            if(!dirs.has(dirpath))
            {
                mkdir_p(PATH.dirname(dirpath));
                
                FS.mkdir(dirpath);
                dirs.add(dirpath);
            }
        };

        for(const {path, contents} of files.sort((lhs, rhs) => lhs['path'] < rhs['path'] ? -1 : 1))
        {
            const absolute_path = PATH.join2(this.project_dir, path);
            if(contents == null)
                mkdir_p(absolute_path);
            else
            {
                mkdir_p(PATH.dirname(absolute_path));
                FS.writeFile(absolute_path, contents);
            }
        }
        
        const dirname = main_tex_path.slice(0, main_tex_path.length - source_name.length) || '.';
        const source_dir = PATH.join2(this.project_dir, dirname);
        FS.chdir(source_dir);
       
        if(bibtex == null)
            bibtex = files.some(({path, contents}) => contents != null && path.endsWith('.bib'));
        
        const cmds = bibtex ? [xetex, bibtex8, xetex, xetex, xdvipdfmx] : [xetex, xdvipdfmx];
        
        let exit_code = 0;
        const mem_header = Uint8Array.from(Module.HEAPU8.slice(0, this.mem_header_size));
        for(const cmd of cmds)
        {
            exit_code = NOCLEANUP_callMain(Module, cmd, this.print);
            Module.HEAPU8.fill(0);
            Module.HEAPU8.set(mem_header);
            
            Module.setStatus(`EXIT CODE: ${exit_code}`);
            //if(exit_code != 0)
            //    break;
        }

        const pdf = exit_code == 0 && FS.analyzePath(pdf_path).exists ? FS.readFile(pdf_path, {encoding: 'binary'}) : null;
        const log = FS.analyzePath(log_path).exists ? FS.readFile(log_path, {encoding : 'utf8'}) : null;
        
        FS.unmount(this.project_dir);
        this.Module = this.preload == false ? null : this.Module;
        
        return {pdf : pdf, log : log};
    }
}
