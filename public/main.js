const texmf_local = ['./texmf', './.texmf'];

const paths_list = Array.from(document.head.getElementsByTagName('link')).filter(link => link.rel == 'busytex').map(link => [link.id, link.href]);
const texlive_data_packages_js = paths_list.filter(([id, href]) => id.startsWith('texlive_')).map(([id, href]) => href);
const paths = { ...Object.fromEntries(paths_list), texlive_data_packages_js : texlive_data_packages_js };

let worker = null;
let texEditor = null;
let bibEditor = null;

const workerCheckbox = document.getElementById('worker');
const preloadCheckbox = document.getElementById('preload');
const verboseSelect = document.getElementById('verbose');
const driverSelect = document.getElementById('tex_driver');
const bibtexCheckbox = document.getElementById('bibtex');
const autoCheckbox = document.getElementById('checked_texlive_auto');
const previewElement = document.getElementById('preview');
const elapsedElement = document.getElementById('elapsed');
const ubuntuPackageCheckboxes = {
    recommended: document.getElementById('checked_texlive_ubuntu_recommended'),
    extra: document.getElementById('checked_texlive_ubuntu_extra'),
    science: document.getElementById('checked_texlive_ubuntu_science')
};

async function onclick_()
{
    const use_worker = workerCheckbox.checked;
    const use_preload = preloadCheckbox.checked;
    const use_verbose = verboseSelect.value;
    const use_driver = driverSelect.value;
    const use_bibtex = bibtexCheckbox.checked;
    const use_auto = autoCheckbox.checked;

    let data_packages_js = null;
    if(!use_auto)
    {
        data_packages_js = [];
        for(const [key, checkbox] of Object.entries(ubuntuPackageCheckboxes))
        {
            if(checkbox.checked)
                data_packages_js.push(texlive_data_packages_js.find(path => path.includes(key)));
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
            previewElement.src = URL.createObjectURL(new Blob([pdf], {type: 'application/pdf'}));
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
    const tex = texEditor.getValue();
    const bib = bibEditor.getValue();
    const files = [{path : 'example.tex', contents : tex}, {path : 'example.bib', contents : bib}];
    worker.postMessage({files : files, main_tex_path : 'example.tex', verbose : use_verbose, bibtex : use_bibtex, driver : use_driver, data_packages_js : data_packages_js});
}

function terminate()
{
    if(worker != null)
        worker.terminate();
    worker = null;
}

require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.21.2/min/vs' }});
require(['vs/editor/editor.main'], function() {
    monaco.languages.register({ id: 'latex' });

    monaco.languages.setMonarchTokensProvider('latex', {
        tokenizer: {
            root: [
                [/\\[a-zA-Z]+/, 'keyword'],
                [/%.*/, 'comment'],
                [/\{[^}]*\}/, 'string'],
                [/\[[^\]]*\]/, 'string'],
                [/\$[^$]*\$/, 'string'],
            ]
        }
    });

    texEditor = monaco.editor.create(document.getElementById('tex-editor'), {
        value: `% This is a simple sample document.  For more complicated documents take a look in the exercise tab. Note that everything that comes after a % symbol is treated as comment and ignored when the code is compiled.

\\documentclass{article} % \\documentclass{} is the first command in any LaTeX code.  It is used to define what kind of document you are creating such as an article or a book, and begins the document preamble

\\usepackage{amsmath} % \\usepackage is a command that allows you to add functionality to your LaTeX code

\\title{Simple Sample} % Sets article title
\\author{My Name} % Sets authors name
\\date{\\today} % Sets date for date compiled

% The preamble ends with the command \\begin{document}
\\begin{document} % All begin commands must be paired with an end command somewhere
    \\maketitle % creates title using information in preamble (title, author, date)
    
    \\section{Hello World!} % creates a section
    
    \\textbf{Hello World!} Today I am learning \\LaTeX. %notice how the command will end at the first non-alphabet charecter such as the . after \\LaTeX
     \\LaTeX{} is a great program for writing math. I can write in line math such as $a^2+b^2=c^2$ %$ tells LaTexX to compile as math
     . I can also give equations their own space: 
    \\begin{equation} % Creates an equation environment and is compiled as math
    \\gamma^2+\\theta^2=\\omega^2
    \\end{equation}
    If I do not leave any blank lines \\LaTeX{} will continue  this text without making it into a new paragraph.  Notice how there was no indentation in the text after equation (1).  
    Also notice how even though I hit enter after that sentence and here $\\downarrow$
     \\LaTeX{} formats the sentence without any break.  Also   look  how      it   doesn't     matter          how    many  spaces     I put     between       my    words.
    
    For a new paragraph I can leave a blank space in my code. 

\\end{document} % This is the end of the document`,
        language: 'latex',
        theme: 'vs-dark'
    });

    bibEditor = monaco.editor.create(document.getElementById('bib-editor'), {
        value: `@misc{Nobody06,
   author = "Nobody Jr",
   title = "My Article",
   year = "2006" 
}`,
        language: 'latex',
        theme: 'vs-dark'
    });
});