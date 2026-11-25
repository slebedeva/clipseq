# rDNA region annotations

BED files (0-based, half-open) marking the rRNA genes and spacers on a single-contig rDNA
reference. Pass one with `--rDNA_regions` to get labelled region boxes in the rDNA summary plot
(`run_rDNA_summary`). Without it the plot has no region boxes.

The first column must match the sequence ID in your `rDNA_fasta` header. Use the matching fasta
below as `rDNA_fasta`. Rows whose name contains `ribosomal RNA` are shaded as rRNA; the rest
(spacers) are shaded grey.

| Species | BED | Reference contig | Length |
| --- | --- | --- | --- |
| Human | `homo_sapiens.U13369.1.bed` | [U13369.1](https://www.ncbi.nlm.nih.gov/nuccore/U13369.1), complete rDNA repeating unit | 42,999 bp |
| Mouse | `mus_musculus.BK000964.3.bed` | [BK000964.3](https://www.ncbi.nlm.nih.gov/nuccore/BK000964.3), complete rDNA repeating unit | 45,306 bp |
| *S. cerevisiae* | `saccharomyces_cerevisiae.NR_132207.1.bed` | [NR_132207.1](https://www.ncbi.nlm.nih.gov/nuccore/NR_132207.1), 35S pre-rRNA (RDN37-1) | 6,858 bp |

Zebrafish is missing: GenBank has no standalone *Danio rerio* rDNA repeat unit (as of 2026-11).

## Re-fetch

Fasta references:

```bash
for acc in U13369.1 BK000964.3 NR_132207.1; do
  curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${acc}&rettype=fasta&retmode=text" > ${acc}.fa
done
```

Human and mouse BEDs come straight from the record's GenBank feature table:

```bash
for pair in homo_sapiens:U13369.1 mus_musculus:BK000964.3; do
  species=${pair%%:*}; acc=${pair#*:}
  curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${acc}&rettype=ft&retmode=text" |
    awk -v acc="$acc" -F'\t' '
      /^[<>0-9]/ { gsub(/[<>]/, ""); s=$1; e=$2; t=$3; next }
      $4=="product" && (t=="rRNA" || t=="misc_RNA") { print acc"\t"s-1"\t"e"\t"$5 }' \
    > ${species}.${acc}.bed
done
```

The yeast NR_132207.1 record has no sub-region annotation. Its spacers and rRNAs are taken from
chromosome XII ([NC_001144.5](https://www.ncbi.nlm.nih.gov/nuccore/NC_001144.5):451575-458432,
minus strand) and flipped into NR_132207.1 coordinates:

```bash
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_001144.5&rettype=ft&retmode=text&seq_start=451575&seq_stop=458432" |
  awk -F'\t' -v len=6858 '
    /^[<>0-9]/ { gsub(/[<>]/, ""); s=$1; e=$2; t=$3; next }
    $4=="product" && (t=="rRNA" || t=="misc_RNA") && $5 !~ /35S/ { print "NR_132207.1\t"len-s"\t"len-e+1"\t"$5 }' |
  sort -k2,2n > saccharomyces_cerevisiae.NR_132207.1.bed
```

Note: in BK000964.3, NCBI annotates 28S and 3'ETS with a 1 nt overlap; it is kept as-is.
