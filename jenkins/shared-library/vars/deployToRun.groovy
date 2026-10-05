// Deploy the image to Cloud Run using the demo runtime service account.
def call(Map config = [:]) {
    def service = config.service ?: 'demo'
    def region = config.region
    def project = config.project
    def image = config.image
    def runtimeSa = config.runtimeSa ?: ''
    def allowUnauth = config.allowUnauthenticated ?: true

    def saFlag = runtimeSa ? "--service-account ${runtimeSa}" : ''
    def authFlag = allowUnauth ? '--allow-unauthenticated' : '--no-allow-unauthenticated'

    echo "Deploying ${service} to Cloud Run (${region})"
    sh """
        gcloud run deploy ${service} \
            --image ${image} \
            --region ${region} \
            --project ${project} \
            ${saFlag} \
            ${authFlag} \
            --port 8080 \
            --quiet
    """
}
