#!/usr/bin/env node

const kinfer = {}
const program = require('commander')
const path = require('path')
const promisify = require('util').promisify
const fs = require('fs')
const spawn = require('child_process').spawn
const chalk = require('chalk')

const KU = path.resolve(__dirname, '../kindleunpack.exe')
const KG = path.resolve(__dirname, '../kindlegen.exe')
const KS = path.resolve(__dirname, '../kindlestrip.exe')


const fsp = {
    stat: promisify(fs.stat),
    rename: promisify(fs.rename)
}

const TOOL = {
    rmdir(path) {
        if (fs.existsSync(path)) {
            fs.readdirSync(path).forEach((file) => {
                let curPath = path + "/" + file;
                if (fs.lstatSync(curPath).isDirectory()) {
                    this.rmdir(curPath);
                } else {
                    fs.unlinkSync(curPath);
                }
            });
            fs.rmdirSync(path);
        }
    }
}
let total = 1;
let count = 0;

kinfer.cmd = function () {
    program
        .usage('-s [string]')
        .option('-s, --source [string]', 'source file or source dir')

    program.on('--help', function () {
        console.log('')
        console.log('Examples:');
        console.log('  kinfer -s [filename].epub');
        console.log('  kinfer -s [filename].azw3');
        console.log('  kinfer -s [dirname]');
    });

    program.parse(process.argv);
}


kinfer.init = async function () {
    this.cmd()
    let source = program.source;
    if (!source) {
        console.log(chalk.red("Miss -s or --source param, using kinfer -h for help"))
        return
    }
    if (!path.isAbsolute(source)) {
        source = path.resolve(source)
    }

    let stat;
    try {
        stat = await fsp.stat(source)
    } catch (e) {
        console.log(chalk.yellow("File or dir not found, exit."))
        return
    }

    if (stat.isDirectory(stat)) {
        const files = fs.readdirSync(source)
        total = files.length;
        if(!total){
            console.log(chalk.yellow("The dir is empty, exit."))
        }else{
            files.forEach(file => {
                const filename = path.resolve(source, file)
                kinfer.transFile(filename)
            })
        }
    } else if (stat.isFile()) {
        kinfer.transFile(source)
    }
}

kinfer.transFile = async function (filename) {
    const extname = path.extname(filename)
    if (extname === '.azw3') {
        kinfer.transAZW3(filename)
    } else if (extname === '.epub') {
        kinfer.transEPUB(filename)
    } else {
        count++;
        console.log(chalk.yellow("The file cann't be resolved for it is not azw3 or epub format."))
    }
}

kinfer.transEPUB = function (filename) {
    const p1 = spawn(KG, [filename])

    p1.on('close', () => {
        console.log(chalk.green('Successful tranform to mobi'))
        const basename = path.basename(filename, path.extname(filename));
        const mobi = path.join(path.dirname(filename), basename + '.mobi')
        const p2 = spawn(KS, [mobi, mobi])
        p2.on('close', () => {
            count++;
            console.log(chalk.green(`Compress mobi success, finish ${(count/total)*100}%`))
        })
    })
}

kinfer.transAZW3 = function (filename) {
    const p1 = spawn(KU, [filename])
    const dirname = path.dirname(filename)
    const basename = path.basename(filename, path.extname(filename))
    const epub = path.resolve(dirname, basename, 'mobi8', `${basename}.epub`)

    p1.on('close', async () => {
        console.log(chalk.green('Successful tranform to epub'))
        const epubNew = path.resolve(dirname, `${basename}.epub`)
        await fsp.rename(epub, epubNew)
        TOOL.rmdir(path.resolve(dirname, basename))
        kinfer.transEPUB(epubNew)
    })
}

kinfer.init()

module.exports = kinfer