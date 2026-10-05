// Fail the build on HIGH/CRITICAL vulnerabilities in the built image.
def call(Map config = [:]) {
    def image = config.image
    def severity = config.severity ?: 'HIGH,CRITICAL'
    def exitCode = config.exitCode ?: 1

    echo "Scanning ${image} for ${severity} vulnerabilities"
    sh "trivy image --severity ${severity} --exit-code ${exitCode} --ignore-unfixed ${image}"
}
