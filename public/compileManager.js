document.addEventListener('DOMContentLoaded', () => {
    const compileButton = document.getElementById("compile-button");
    if (!compileButton) {
        console.error("Compile button not found!");
        return;
    }

    compileButton.addEventListener("click", onclick_);
});

async function onclick_() {
    if (compileButton.classList.contains('compiling')) {
        // Handle stop compilation
        terminate();
        compileButton.classList.remove('compiling');
        compileButton.innerText = "Compile";
        if (spinnerElement) {
            spinnerElement.style.display = 'none';
        }
        return;
    }

    // Start compilation
    compileButton.classList.add('compiling');
    compileButton.innerText = "Stop compilation";
    
    if (spinnerElement) {
        spinnerElement.style.display = 'block';
    }

    const use_worker = workerCheckbox.checked;
    const use_preload = preloadCheckbox.checked;
    const use_verbose = verboseSelect.value;
    const use_driver = driverSelect.value;
    const use_bibtex = bibtexCheckbox.checked;
    const use_auto = autoCheckbox.checked;

        let data_packages_js = null;
        if (!use_auto) {
            data_packages_js = [];
            for (const [key, checkbox] of Object.entries(ubuntuPackageCheckboxes)) {
                if (checkbox.checked)
                    data_packages_js.push(texlive_data_packages_js.find(path => path.includes(key)));
            }
        }

        let tic = performance.now();
        const reload = worker == null;
        if (use_worker) {
            if (reload) worker = new Worker(paths.busytex_worker_js);
        } else if (reload) {
            worker = {
                async postMessage({ files, main_tex_path, bibtex, preload, verbose, busytex_js, busytex_wasm, texmf_local, preload_data_packages_js, data_packages_js }) {
                    if (busytex_wasm && busytex_js && preload_data_packages_js) {
                        this.pipeline = new Promise((resolve, reject) => {
                            let script = document.createElement('script');
                            script.src = busytex_pipeline_js;
                            script.onload = resolve;
                            script.onerror = reject;
                            document.head.appendChild(script);
                        }).then(_ => Promise.resolve(new BusytexPipeline(
                            busytex_js, busytex_wasm, data_packages_js, preload_data_packages_js,
                            texmf_local, msg => this.onmessage({ data: { log: msg } }),
                            preload, BusytexPipeline.ScriptLoaderDefault
                        )));
                    } else if (files && this.pipeline) {
                        const pipeline = await this.pipeline;
                        const pdf = await self.pipeline.compile(files, main_tex_path, bibtex, verbose, driver, data_packages_js);
                        this.onmessage({ data: { pdf } });
                    }
                },
                terminate() {
                    this.onmessage({ data: { log: 'Terminating dummy worker' } });
                }
            };
        }

    worker.onmessage = ({ data : {pdf, log, print} }) =>
    {
        if(pdf)
        {
            previewElement.src = URL.createObjectURL(new Blob([pdf], {type: 'application/pdf'}));
            elapsedElement.innerText = ((performance.now() - tic) / 1000).toFixed(2) + ' sec';
            if (spinnerElement) {
                spinnerElement.style.display = 'none';   // Hide spinner
            }
            compileButton.classList.remove('compiling');
            compileButton.innerText = "Compile";
            console.log('Compilation successful');
        }

        if(print)
        {
            console.log(print);
        }
    }
    
    if(reload)
        worker.postMessage({...paths, texmf_local : texmf_local, preload_data_packages_js : paths.texlive_data_packages_js.slice(0, 1), data_packages_js : paths.texlive_data_packages_js});

    tic = performance.now();
    const tex = texEditor.getValue();
    const bib = bibEditor.getValue();
    const files = [{path : 'example.tex', contents : tex}, {path : 'example.bib', contents : bib}];
    worker.postMessage({files : files, main_tex_path : 'example.tex', verbose : use_verbose, bibtex : use_bibtex, driver : use_driver, data_packages_js : data_packages_js});
}

function terminate() {
    if (worker !== null) worker.terminate();
    worker = null;
}