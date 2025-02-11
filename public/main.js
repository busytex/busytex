const texmf_local = ['./texmf', './.texmf'];

const paths_list = Array.from(document.head.getElementsByTagName('link')).filter(link => link.rel == 'busytex').map(link => [link.id, link.href]);
const texlive_data_packages_js = paths_list.filter(([id, href]) => id.startsWith('texlive_')).map(([id, href]) => href);
const paths = { ...Object.fromEntries(paths_list), texlive_data_packages_js : texlive_data_packages_js };

let worker = null;

async function onclick_()
{
    const use_worker = document.getElementById('worker').checked;
    const use_preload = document.getElementById('preload').checked;
    const use_verbose = document.getElementById('verbose').value;
    const use_driver = document.getElementById('tex_driver').value;
    const use_bibtex = document.getElementById('bibtex').checked;
    const use_auto = document.getElementById('checked_texlive_auto').checked;

    let data_packages_js = null;
    if(!use_auto)
    {
        data_packages_js = [];
        for(const ubuntu_package_name of ['texlive_ubuntu_recommended', 'texlive_ubuntu_extra', 'texlive_ubuntu_science'])
        {
            const checked = document.getElementById('checked_' + ubuntu_package_name).checked;
            if(checked)
                data_packages_js.push(texlive_data_packages_js.find(path => path.includes(ubuntu_package_name)));
        }
    }

    let tic = 0;
    
    const reload = worker == null;
    if(use_worker)
    {
        if(reload)
            worker = new Worker(paths.busytex_worker_js);
    }
    else if(reload)
    {
        worker = 
        {
            async postMessage({files, main_tex_path, bibtex, preload, verbose, busytex_js, busytex_wasm, texmf_local,  preload_data_packages_js, data_packages_js})
            {
                if(busytex_wasm && busytex_js && preload_data_packages_js)
                {
                    this.pipeline = new Promise(function (resolve, reject)
                    {
                        let s = document.createElement('script');
                        s.src = busytex_pipeline_js;
                        s.onload = resolve;
                        s.onerror = reject;
                        self.document.head.appendChild(s);
                    }).then(_ => Promise.resolve(new BusytexPipeline(busytex_js, busytex_wasm, data_packages_js, preload_data_packages_js, texmf_local, msg => this.onmessage({data: {log : msg}}), preload, BusytexPipeline.ScriptLoaderDefault)));
                }

                else if(files && this.pipeline)
                {
                    const pipeline = await this.pipeline;
                    const pdf = await self.pipeline.compile(files, main_tex_path, bibtex, verbose, driver, data_packages_js)
                    this.onmessage({data : {pdf : pdf}});
                }
            },

            terminate()
            {
                this.onmessage({data : {log : 'Terminating dummy worker'}});
            }
        }
    }

    worker.onmessage = ({ data : {pdf, log, print} }) =>
    {
        if(pdf)
        {
            let previewElement = document.getElementById('preview');
            previewElement.src = URL.createObjectURL(new Blob([pdf], {type: 'application/pdf'}));

            let elapsedElement = document.getElementById('elapsed');
            elapsedElement.innerText = ((performance.now() - tic) / 1000).toFixed(2) + ' sec';
        }

        if(print)
        {
            console.log(print);
        }
    }
    

    if(reload)
        worker.postMessage({...paths, texmf_local : texmf_local, preload_data_packages_js : paths.texlive_data_packages_js.slice(0, 1), data_packages_js : paths.texlive_data_packages_js});

    tic = performance.now();
    const tex = document.getElementById('tex').value, bib = document.getElementById('bib').value;
    const files = [{path : 'example.tex', contents : tex}, {path : 'example.bib', contents : bib}];
    worker.postMessage({files : files, main_tex_path : 'example.tex', verbose : use_verbose, bibtex : use_bibtex, driver : use_driver, data_packages_js : data_packages_js});
}

function terminate()
{
    if(worker != null)
        worker.terminate();
    worker = null;
}