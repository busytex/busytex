importScripts('busytex_pipeline.js');

onmessage = async ({data : {files, main_tex_path, bibtex, busytex_wasm, busytex_js, texlive_js, texmf_local, exit_early, verbose}}) => 
{
    if(busytex_wasm && busytex_js && texlive_js)
        pipeline = new BusytexPipeline(busytex_js, busytex_wasm, texlive_js, texmf_local, msg => postMessage({print : msg}), BusytexWorkerScriptLoader);
    else if(files && pipeline)
        postMessage(await pipeline.compile(files, main_tex_path, bibtex, exit_early, verbose))
};
