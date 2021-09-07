importScripts('busytex_pipeline.js');

self.pipeline = null;

onmessage = async ({data : {files, main_tex_path, bibtex, busytex_wasm, busytex_js, preload_data_packages_js, data_packages_js, texmf_local, preload, verbose, driver}}) => 
{
    // TODO: cache data packages from here? https://developer.mozilla.org/en-US/docs/Web/API/Cache
    
    if(busytex_wasm && busytex_js && preload_data_packages_js)
    {
        try
        {
            self.pipeline = new BusytexPipeline(busytex_js, busytex_wasm, data_packages_js, preload_data_packages_js, texmf_local, msg => postMessage({print : msg}), applet_versions => postMessage({ initialized : applet_versions }), preload, BusytexPipeline.ScriptLoaderWorker);
        }
        catch(err)
        {
            postMessage({exception: 'Exception during initialization: ' + err.toString() + '\nStack:\n' + err.stack});
        }
    }
    else if(files && self.pipeline)
    {
        try
        {
            postMessage(await self.pipeline.compile(files, main_tex_path, bibtex, verbose, driver, data_packages_js))
        }
        catch(err)
        {
            postMessage({exception: 'Exception during compilation: ' + err.toString() + '\nStack:\n' + err.stack});
        }
    }
};
