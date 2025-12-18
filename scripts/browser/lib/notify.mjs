import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function notify(title, message, subtitle = '') {
  try {
    const args = [
      '/opt/homebrew/bin/terminal-notifier',
      '-title', `"${title}"`,
      '-message', `"${message}"`,
      '-sound', 'default'
    ];

    if (subtitle) {
      args.push('-subtitle', `"${subtitle}"`);
    }

    await execAsync(args.join(' '));
  } catch (err) {
    console.error('Notification failed:', err.message);
  }
}
