import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { loadProjectsFromFirestore, explorerTree } from './projectManager.js';
import { initializeEditor } from './editorManager.js';
import { renderFileExplorer, setupContextMenuHandlers } from './uiManager.js';
import { onclick_, terminate } from './compileManager.js';  // Add this import

// Load projects and initialize UI
async function initApp() {
    try {
        const uiState = await loadProjectsFromFirestore();
        initializeEditor();
        renderFileExplorer(document.getElementById('file-tree'), explorerTree, uiState);
        setupContextMenuHandlers();

       /*
       * IL WASM DOVREMMO INIZIALIZZARLO QUI
       *
       * 
        project_dir = '/home/web_user/project_dir';

        WebAssembly.instantiate(wasm_module, imports).then(output => successCallback(WebAssembly.compileStreaming ? output : output.instance)).catch(err => {throw new Error('Error while initializing BusyTex!\n\n' + err.toString())});

        if(FS.analyzePath(this.project_dir).object.mount.mountpoint == this.project_dir)
            FS.unmount(this.project_dir);
        FS.mount(FS.filesystems.MEMFS, {}, this.project_dir);

        let dirs = new Set(['/', this.project_dir]);
        for(const {path, contents} of files.sort((lhs, rhs) => lhs['path'] < rhs['path'] ? -1 : 1))
        {
            const absolute_path = PATH.join(this.project_dir, path);
            if(contents == null)
                this.mkdir_p(FS, PATH, absolute_path, dirs);
            else
            {
                this.mkdir_p(FS, PATH, PATH.dirname(absolute_path), dirs);
                FS.writeFile(absolute_path, contents);
            }
        }
        
        const source_dir = PATH.join(this.project_dir, dirname);
        FS.chdir(source_dir);


        */

            } catch (error) {
        console.error("Error initializing app:", error);
    }
}

// Start the application
initApp();