importScripts('busytex_pipeline.js');

self.pipeline = null;

//TODO: handle exceptions and post back error log

onmessage = async ({data : {files, main_tex_path, bibtex, busytex_wasm, busytex_js, preload_data_packages_js, data_packages_js, texmf_local, preload, verbose, driver}}) => 
{
    if(busytex_wasm && busytex_js && preload_data_packages_js)
        self.pipeline = new BusytexPipeline(busytex_js, busytex_wasm, preload_data_packages_js, texmf_local, msg => postMessage({print : msg}), preload, BusytexPipeline.ScriptLoaderWorker);

    else if(files && self.pipeline)
        postMessage(await self.pipeline.compile(files, main_tex_path, bibtex, verbose, driver, data_packages_js))
};
