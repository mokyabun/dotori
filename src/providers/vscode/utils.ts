import fs from 'fs'
import path from 'path'
import { VSCODE_USER_DIR } from './constants'

export function profileArgs(profileName: string): string[] {
    return profileName === 'default' ? [] : ['--profile', profileName]
}

export function readJsonFile(filePath: string): Record<string, unknown> {
    try {
        return JSON.parse(fs.readFileSync(filePath, 'utf8'))
    } catch {
        return {}
    }
}

export function settingsPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'settings.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'settings.json')
}

export function keybindingsPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'keybindings.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'keybindings.json')
}

export function tasksPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'tasks.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'tasks.json')
}

export function mcpPath(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'mcp.json')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'mcp.json')
}

export function snippetsDir(name: string): string {
    return name === 'default'
        ? path.join(VSCODE_USER_DIR, 'snippets')
        : path.join(VSCODE_USER_DIR, 'profiles', name, 'snippets')
}
