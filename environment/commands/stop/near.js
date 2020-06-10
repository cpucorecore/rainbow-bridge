const { execSync } = require('child_process');

class StopLocalNearNodeCommand {
    static execute () {
        console.log('Stopping local near node...');
        const command = '~/.rainbowup/nearup/nearup stop';
        try {
        	execSync(command);
        } catch (err) {
            console.log('Error stopping local near node', err);
        }
    }
}

exports.StopLocalNearNodeCommand = StopLocalNearNodeCommand;