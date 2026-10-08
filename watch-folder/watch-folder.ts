import { watch, statSync, readdirSync } from "node:fs";
import { join, extname } from "node:path";


let folder = process.argv[2] ?? process.env.HOME + "/Downloads";

//ffied
declare function menuInit(): void;
declare function menuPoll(): void;
declare function menuGetAction(): number;
declare function menuGetAudioEnabled(): number;
declare function menuSetPaused(paused: number): void;
declare function menuSetFolder(path: string): void;
// declare function menuGetSelectedFolder(): string;
declare function menuCopySelectedFolder(
    buffer: Uint8Array,
    capacity: number
): number;
let paused = false;

menuInit();
menuSetFolder(folder);
startWatching(folder);
setInterval(() => {
    menuPoll();

    const action = menuGetAction();

    if (action === 1) {
        const selected = getSelectedFolder();

        if (selected && selected !== folder) {
            startWatching(selected);
        }
    }

    if (action === 2) {
        paused = !paused;
        menuSetPaused(paused ? 1 : 0);
    }

    if (action === 3) {
        process.exit(0);
    }
}, 50);
// Bound through scriptc FFI
declare function playAudio(path: string): number;


function checkForNewFiles(): void {
    const currentFiles = readdirSync(folder);
    const currentSet = new Set(currentFiles);

    for (const filename of currentFiles) {
        if (!knownFiles.has(filename)) {
            console.log("New file:", filename);
            void handleFile(filename);
        }
    }

    knownFiles = currentSet;
}

function getSelectedFolder(): string {
    const buffer = new Uint8Array(4096);
    const length = menuCopySelectedFolder(buffer, buffer.length);

    if (length <= 0) return "";

    return new TextDecoder().decode(buffer.subarray(0, length));
}
const audioExtensions = new Set([
    ".mp3", ".m4a", ".aac",
    ".wav", ".aiff", ".aif",
]);

const pending = new Set<string>();

function waitForCopy(path: string): Promise<void> {
    return new Promise((resolve, reject) => {
        let previousSize = -1;
        let stable = 0;

        const timer = setInterval(() => {
            try {
                const info = statSync(path);

                if (info.size === previousSize) {
                    stable++;
                } else {
                    previousSize = info.size;
                    stable = 0;
                }

                if (stable >= 3) {
                    clearInterval(timer);
                    resolve();
                }
            } catch (err) {
                clearInterval(timer);
                reject(err);
            }
        }, 1000);
    });
}

console.log('watching:: ', folder)


let knownFiles = new Set<string>();
let scanGeneration = 0;
let watcher: ReturnType<typeof watch>;

function startWatching(newFolder: string): void {
    // Stop watching the previous folder
    if (watcher) {
        watcher.close();
    }

    folder = newFolder;

    // Take a snapshot so existing files aren't treated as new
    knownFiles = new Set(readdirSync(folder));

    // Invalidate scans scheduled by the previous watcher
    scanGeneration++;

    watcher = watch(folder, {}, (_eventType: string) => {
        const generation = ++scanGeneration;

        setTimeout(() => {
            if (generation !== scanGeneration) return;
            checkForNewFiles();
        }, 250);
    });

    menuSetFolder(folder);
    console.log("Now watching:", folder);
}

async function handleFile(filename: string): Promise<void> {
    const path = join(folder, filename);
    console.log('Handling', path)

    if (!audioExtensions.has(extname(filename).toLowerCase())) {
        return;
    }

    if (pending.has(path)) return;
    pending.add(path);

    try {
        await waitForCopy(path);

        console.log(`Playing: ${path}`);
        if (paused) return;
        if (menuGetAudioEnabled()) {
            if (!playAudio(path)) {
                console.error(`Playback failed: ${path}`);
            }
        }

    } catch (err) {
        console.error(`File error: ${path}`, err);
    } finally {
        pending.delete(path);
    }
}