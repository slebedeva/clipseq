process CLIPQC {
    label "process_single"

    conda (params.enable_conda ? "bioconda::pybedtools=0.9.0 pandas=1.5.0" : null)
    container "quay.io/goodwright/mulled-v2-9617f1b1a927f74fecc0c8b26ec773df8a8593b7:78688d5e3c856e3fbba8a63a7740b414dc4c0c5a-0"

    input:
    val callers
    path("premap/*")
    path("mapped/*")
    path("collapse/*")
    tuple val(xlinks_ids)  , path(xlinks  , stageAs: "xlinks/*")
    tuple val(icount_ids)  , path(icount  , stageAs: "icount/*")
    tuple val(paraclu_ids) , path(paraclu , stageAs: "paraclu/*")
    tuple val(clippy_ids)  , path(clippy  , stageAs: "clippy/*")
    tuple val(pureclip_ids), path(pureclip, stageAs: "pureclip/*")
    path("summary_type/*")
    path("summary_subtype/*")
    path("summary_gene/*")

    output:
    path "*.tsv"         , emit: tsv
    path  "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    shell:
    process_name = task.process
    // "id:path,id:path" strings, parsed by clipqc.py to pair peaks with their crosslinks
    xlinks_pairs   = toPairs(xlinks_ids, xlinks)
    icount_pairs   = toPairs(icount_ids, icount)
    paraclu_pairs  = toPairs(paraclu_ids, paraclu)
    clippy_pairs   = toPairs(clippy_ids, clippy)
    pureclip_pairs = toPairs(pureclip_ids, pureclip)
    template 'clipqc.py'
}

// Join ids and their staged files as "id:path,id:path" (empty string when there are none)
def toPairs(ids, files) {
    return [ids, [files].flatten()].transpose().collect { i, f -> "${i}:${f}" }.join(',')
}
