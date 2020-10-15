//TODO: custom initialize / reload after a compilation
//TODO: callMain hack: https://github.com/lyze/xetex-js/blob/master/post.worker.js
//TODO: merge DataLoader / script loaders into Pipeline class

function BusytexDefaultScriptLoader(src)
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

function BusytexRequireScriptLoader(src)
{
    return new Promise(resolve => self.require([src], resolve));
}

function BusytexWorkerScriptLoader(src)
{
    return Promise.resolve(self.importScripts(src));
}

BusytexVerboseSilent = 'silent';

BusytexVerboseInfo = 'info';

BusytexVerboseDebug = 'debug';

BusytexDataLoader = 
{
    //https://emscripten.org/docs/api_reference/module.html#Module.getPreloadedPackage
    //https://github.com/emscripten-core/emscripten/blob/master/tests/manual_download_data.html

    preRun : [],

    locateFile(remote_package_name)
    {
        for(const data_package_js of this.data_packages)
        {
            const data_file = data_package_js.replace('.js', '.data');
            if(data_file.endsWith(remote_package_name))
                return data_file;
        }
        return null;
    },

    data_packages : []
};

class BusytexPipeline
{
    constructor(busytex_js, busytex_wasm, texlive_js, texmf_local, print, script_loader)
    {
        this.print = print;
        this.wasm_module_promise = fetch(busytex_wasm).then(WebAssembly.compileStreaming);
        this.em_module_promise = script_loader(busytex_js);
        
        BusytexDataLoader.data_packages = []
        for(const data_package_js of texlive_js)
        {
            this.em_module_promise = this.em_module_promise.then(_ => script_loader(data_package_js));
            BusytexDataLoader.data_packages.push(data_package_js);
        }
        
        this.ansi_reset_sequence = '\x1bc';
        
        this.project_dir = '/home/web_user/project_dir/';
        this.bin_busytex = '/bin/busytex';
        this.fmt_latex = '/latex.fmt';
        this.dir_texmfdist = ['/texlive', '/texmf', ...texmf_local].map(texmf => (texmf.startsWith('/') ? '' : this.project_dir) + texmf + '/texmf-dist').join(':');
        this.cnf_texlive = '/texmf.cnf';
        this.dir_cnf = '/';
        this.dir_bibtexcsf = '/bibtex';

        this.init_env = ENV =>
        {
            ENV.TEXMFDIST = this.dir_texmfdist;
            ENV.TEXMFCNF = this.dir_cnf;
        };

        this.init_project_dir = (files, source_dir) => (PATH, FS) =>
        {
            FS.mkdir(this.project_dir);
            for(const {path, contents} of files.sort((lhs, rhs) => lhs['path'] < rhs['path'] ? -1 : 1))
            {
                const absolute_path = `${this.project_dir}/${path}`;
                
                if(contents == null)
                    FS.mkdir(absolute_path);
                else
                    FS.writeFile(absolute_path, contents);
            }
            FS.chdir(source_dir);
        };
    }

    async run(arguments_array, init_env, init_fs, exit_early, verbose)
    {
		const ASYNC_callMain = async (Module, args) => 
		{
			return new Promise(resolve =>
			{
				Module['onExit'] = status => resolve(status);
				Module.callMain(args);
            	//Module_['callMain'].apply(Module_, arguments_array[i]);
			});
		};

        const NOCLEANUP_callMain = (Module, args) =>
        {
            Module.setPrefix(args[0]);
            const entryFunction = Module['_main'];
            const argc = args.length+1;
            const argv = Module.stackAlloc((argc + 1) * 4);
            Module.HEAP32[argv >> 2] = Module.allocateUTF8OnStack(Module.thisProgram);
            for (let i = 1; i < argc; i++) 
                Module.HEAP32[(argv >> 2) + i] = Module.allocateUTF8OnStack(args[i - 1]);
            Module.HEAP32[(argv >> 2) + argc] = 0;

            try
            {
                entryFunction(argc, argv);
            }
            catch(e)
            {
                this.print('callMain: ' + e.message);
                return e.status;
            }
            
            return 0;
        }

        const print = this.print;
        //const wasm_module = await this.wasm_module_promise;
        //const em_module = await this.em_module_promise;
        const [wasm_module, em_module] = await Promise.all([this.wasm_module_promise, this.em_module_promise]);

        const Module =
        {
            noInitialRun : true,

            //noExitRuntime : false,

            thisProgram : this.bin_busytex,
            
            totalDependencies: 0,
            
            prefix : "",
            
            preRun : [() =>
            {
                Object.setPrototypeOf(BusytexDataLoader, Module);
                self.LZ4 = Module.LZ4;
                for(const preRun of BusytexDataLoader.preRun) 
                    preRun();

                init_env(Module.ENV);
                init_fs(Module.PATH, Module.FS);
            }],

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
                print((this.statusPrefix || '') + text);
            },
            
            monitorRunDependencies(left)
            {
                this.totalDependencies = Math.max(this.totalDependencies, left);
                Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
            },
        };

        const Module_ = await busytex(Module);
        let exit_code = 0;
        const mem = Uint8Array.from(Module_.HEAPU8);
        for(let i = 0; i < arguments_array.length; i++)
        {
            //exit_code = await ASYNC_callMain(Module_, arguments_array[i]);
        	//Module_.onExit = status => console.log('ONEXIT', status);
            exit_code = NOCLEANUP_callMain(Module_, arguments_array[i], print);
            
            Module_.setStatus(`EXIT_CODE: ${exit_code}`);

            if(exit_code != 0 && exit_early == true)
                break;
            
            if(i < arguments_array.length - 1)
                Module_.HEAPU8.set(mem);
        }
        return [Module_.FS, exit_code];
    }

    async compile(files, main_tex_path, bibtex, exit_early, verbose)
    {
        const source_name = main_tex_path.slice(main_tex_path.lastIndexOf('/') + 1);
        const dirname = main_tex_path.slice(0, main_tex_path.length - source_name.length) || '.';
        const source_dir = `${this.project_dir}/${dirname}`;

        const tex_path = source_name;
        const xdv_path = tex_path.replace('.tex', '.xdv');
        const pdf_path = tex_path.replace('.tex', '.pdf');
        const log_path = tex_path.replace('.tex', '.log');
        const aux_path = tex_path.replace('.tex', '.aux');

        // TEXMFLOG
        const verbose_args = 
        {
            [BusytexVerboseSilent] : {
                xetex : [],
                bibtex8 : [],
                xdvipdfmx : []
            },
            [BusytexVerboseInfo] : {
                xetex: ['-kpathsea-debug', '32'],
                bibtex8 : ['--debug', 'search'],
                xdvipdfmx : ['-v'],
            },
            [BusytexVerboseDebug] : {
                xetex : ['-recorder', '-kpathsea-debug', '63'],
                bibtex8 : ['--debug', 'all'],
                xdvipdfmx : ['-vv'],
            },
            '' : {
                xetex : [],
                bibtex8 : [],
                xdvipdfmx : []
            }
        };
        const xetex = ['xetex', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt_latex, tex_path].concat((verbose_args[verbose] || verbose_args['']).xetex);
        const bibtex8 = ['bibtex8', '--8bit', aux_path].concat((verbose_args[verbose] || verbose_args['']).bibtex8);
        const xdvipdfmx = ['xdvipdfmx', '-o', pdf_path, xdv_path].concat((verbose_args[verbose] || verbose_args['']).xdvipdfmx);

        this.print(this.ansi_reset_sequence);
        this.print(`New compilation started: [${main_tex_path}]`);
        
        if(bibtex == null)
            bibtex = files.some(({path, contents}) => contents != null && path.endsWith('.bib'));
        if(exit_early == null)
            exit_early = true;

        const cmds = bibtex == true ? [xetex, bibtex8, xetex, xetex, xdvipdfmx] : [xetex, xdvipdfmx];
        const [FS, exit_code] = await this.run(cmds, this.init_env, this.init_project_dir(files, source_dir), exit_early, verbose);

        const pdf = exit_code == 0 && FS.analyzePath(pdf_path).exists ? FS.readFile(pdf_path, {encoding: 'binary'}) : null;
        const log = FS.analyzePath(log_path).exists ? FS.readFile(log_path, {encoding : 'utf8'}) : null;
        
        return {pdf : pdf, log : log};
    }
}
