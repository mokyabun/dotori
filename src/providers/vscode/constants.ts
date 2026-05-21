import os from 'os'
import path from 'path'

export const VSCODE_USER_DIR = path.join(os.homedir(), 'Library', 'Application Support', 'Code', 'User')
export const STORAGE_PATH = path.join(VSCODE_USER_DIR, 'globalStorage', 'storage.json')
