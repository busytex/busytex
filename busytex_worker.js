importScripts('busytex_pipeline.js');

self.pipeline = null;

onmessage = async ({data : {files, main_tex_path, bibtex, busytex_wasm, busytex_js, texlive_js, texmf_local, preload, verbose, driver}}) => 
{
    if(busytex_wasm && busytex_js && texlive_js)
        self.pipeline = new BusytexPipeline(busytex_js, busytex_wasm, texlive_js, texmf_local, msg => postMessage({print : msg}), preload, BusytexPipeline.ScriptLoaderWorker);
    else if(files && self.pipeline)
        postMessage(await self.pipeline.compile(files, main_tex_path, bibtex, verbose, driver, texlive_js))
};
