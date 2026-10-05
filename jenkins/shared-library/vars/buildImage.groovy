// Build the runtime image.
def call(Map config = [:]) {
    def image = config.image
    def context = config.context ?: '.'
    def dockerfile = config.dockerfile ?: "${context}/Dockerfile"

    echo "Building runtime image ${image} from ${context}"
    sh "docker build --file ${dockerfile} --target runtime --tag ${image} ${context}"
}
