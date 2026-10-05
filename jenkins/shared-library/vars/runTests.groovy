// Run the unit tests inside the Dockerfile's 'test' stage. A failing test fails
// the docker build, which fails the pipeline - quality enforced at the source.
def call(Map config = [:]) {
    def context = config.context ?: '.'
    def dockerfile = config.dockerfile ?: "${context}/Dockerfile"

    echo "Running tests in the 'test' build stage (${context})"
    sh "docker build --file ${dockerfile} --target test ${context}"
}
