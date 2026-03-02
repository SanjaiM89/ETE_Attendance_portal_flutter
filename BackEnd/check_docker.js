const { execSync } = require('child_process');
try {
    console.log(execSync('docker ps -a | grep mongo').toString());
    console.log(execSync('docker logs --tail 20 mongodb-ete').toString());
} catch (e) {
    console.error("Error executing:", e.message);
    if (e.stdout) console.log("STDOUT:", e.stdout.toString());
    if (e.stderr) console.log("STDERR:", e.stderr.toString());
}
