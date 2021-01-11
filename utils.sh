log() {
    echo $LOG_PREFIX $@ >&2
}


fatal() {
    log $@
    exit 1
}
