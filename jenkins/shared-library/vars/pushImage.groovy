// Authenticate Docker to Artifact Registry and push the image.
// Authentication uses the VM's attached service account (metadata), so no
// long-lived key is stored in Jenkins credentials.
def call(Map config = [:]) {
    def image = config.image
    def registryHost = config.registryHost ?: image.split('/')[0]

    echo "Pushing ${image}"
    sh """
        gcloud auth configure-docker ${registryHost} --quiet
        docker push ${image}
    """
}
