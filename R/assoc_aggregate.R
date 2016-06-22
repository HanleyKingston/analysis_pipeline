library(argparser)
library(TopmedPipeline)
library(SeqVarTools)
library(Biobase)
library(GENESIS)
sessionInfo()

argp <- arg_parser("Association test - aggregate")
argp <- add_argument(argp, "config", help="path to config file")
argp <- add_argument(argp, "--chromosome", help="chromosome number (1-24)", type="integer")
argv <- parse_args(argp)
config <- readConfig(argv$config)
chr <- argv$chromosome

# add parameters for:
# user-specified weights

required <- c("gds_file",
              "null_model_file",
              "phenotype_file",
              "aggregate_variant_file")
optional <- c("alt_freq_range"="0 1",
              "out_file"="assoc_aggregate.RData",
              "pval_skat"="kuonen",
              "rho"="0",
              "test"="burden",
              "test_type"="score",
              "weight_beta"="0.5 0.5")
config <- setConfigDefaults(config, required, optional)
print(config)

## gds file can have two parts split by chromosome identifier
gdsfile <- config["gds_file"]
outfile <- config["out_file"]
varfile <- config["aggregate_variant_file"]
if (!is.na(chr)) {
    if (chr == 23) chr <- "X"
    if (chr == 24) chr <- "Y"
    gdsfile <- insertChromString(gdsfile, chr, err="gds_file")
    outfile <- insertChromString(outfile, chr, err="out_file")
    varfile <- insertChromString(varfile, chr, err="aggregate_variant_file")
}
    
gds <- seqOpen(gdsfile)

# get null model
nullModel <- getobj(config["null_model_file"])

# get samples included in null model
sample.id <- nullModel$scanID

# get aggregate list
aggVarList <- getobj(varfile)

# get phenotypes
annot <- getobj(config["phenotype_file"])

# createSeqVarData object
seqData <- SeqVarData(gds, sampleData=annot)

test <- switch(tolower(config["test"]),
               burden="Burden",
               skat="SKAT")

test.type <- switch(tolower(config["test_type"]),
                    firth="Firth",
                    score="Score",
                    wald="Wald")

af.range <- as.numeric(strsplit(config["alt_freq_range"], " ", fixed=TRUE)[[1]])
weights <- as.numeric(strsplit(config["weight_beta"], " ", fixed=TRUE)[[1]])
rho <- as.numeric(strsplit(config["rho"], " ", fixed=TRUE)[[1]])
pval <- tolower(config["pval_skat"])

assoc <- assocTestSeq(seqData, nullModel, aggVarList,
                      test=test,
                      burden.test=test.type,
                      AF.range=af.range,
                      weight.beta=weights,
                      rho=rho,
                      pval.method=pval)

save(assoc, file=outfile)

seqClose(seqData)