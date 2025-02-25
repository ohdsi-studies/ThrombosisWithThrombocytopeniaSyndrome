############### Note this is a custom script, a version of CodeToRun.R that may not work for everyone ##############
############### Please use CodeToRun.R as it a more generic version  ###############################################

############### This version of code will loop over each database ids in serial                      ###############

############### processes to run Cohort Diagnostics ################################################################
library(magrittr)

################################################################################
# VARIABLES - please change
################################################################################
# The folder where the study intermediate and result files will be written:
outputFolder <- "D:/studyResults/SkeletonCohortDiagnosticsStudy"
# create output directory if it does not exist
if (!dir.exists(outputFolder)) {
  dir.create(outputFolder,
             showWarnings = FALSE,
             recursive = TRUE)
}
# Optional: specify a location on your disk drive that has sufficient space.
# options(andromedaTempFolder = "s:/andromedaTemp")

# set to false if email is not possible
mailFatal <- FALSE

# do you want to upload the results to a local database
uploadToLocalPostGresDatabase <- FALSE

############## databaseIds to run cohort diagnostics on that source  #################
databaseIds <-
  c(
    'truven_ccae',
    'truven_mdcd',
    'truven_mdcr',
    'cprd',
    'jmdc',
    'optum_extended_dod',
    'optum_ehr',
    'ims_australia_lpd',
    'ims_germany',
    'ims_france'
  )

## service name for keyring for db with cdm
keyringUserService <- 'OHDSI_USER'
keyringPasswordService <- 'OHDSI_PASSWORD'

## service name for keyring for postgres db to upload results
keyringUserServicePostGresUpload <- 'shinydbUser'
keyringPasswordServicePostGresUpload <- 'shinydbPW'
keyringDatabaseServicePostGresUpload <- 'shinydbDatabase'
keyringServerServicePostGresUpload <- 'shinydbServer'
keyringPortServicePostGresUpload <- 'shinydbPort'

# lets get meta information for each of these databaseId. This includes connection information.
source("extras/examplesOfCodeToRun/dataSourceInformation.R")
cdmSources <- cdmSources2
rm("cdmSources2")

## if uploading to co-ordinator site
privateKeyFileName <- ""
siteUserName <- ""

###### create a list object that contain connection and meta information for each data source
x <- list()
for (i in (1:length(databaseIds))) {
  databaseId <- databaseIds[[i]]
  cdmSource <- cdmSources %>%
    dplyr::filter(.data$sequence == 1) %>% 
    dplyr::filter(database == databaseId)
  
  if (uploadToLocalPostGresDatabase) {
    uploadToLocalPostGresDatabaseSpecifications <- list(
      connectionDetails = DatabaseConnector::createConnectionDetails(
        dbms = "postgresql",
        server = paste(
          keyring::key_get(keyringServerServicePostGresUpload),
          keyring::key_get(keyringDatabaseServicePostGresUpload),
          sep = "/"
        ),
        port = keyring::key_get(keyringPortServicePostGresUpload),
        user = keyring::key_get(keyringUserServicePostGresUpload),
        password = keyring::key_get(keyringPasswordServicePostGresUpload)
      ),
      schema = 'SkeletonCohortDiagnosticsStudy',
      zipFileName = list.files(
        path = file.path(outputFolder, databaseId),
        pattern = paste0("Results_", databaseId, ".zip"),
        full.names = TRUE,
        recursive = TRUE
      )
    )
  } else {
    uploadToLocalPostGresDatabaseSpecifications <- ''
  }
  
  x[[i]] <- list(
    cdmSource = cdmSource,
    generateCohortTableName = TRUE,
    verifyDependencies = TRUE,
    databaseId = databaseId,
    outputFolder = file.path(outputFolder, databaseId),
    userService = keyringUserService,
    passwordService = keyringPasswordService,
    preMergeDiagnosticsFiles = TRUE,
    privateKeyFileName = privateKeyFileName,
    userName = siteUserName,
    uploadToLocalPostGresDatabaseSpecifications = uploadToLocalPostGresDatabaseSpecifications
  )
}


############ executeOnMultipleDataSources #################
# x <- x[1:2]

for (i in (1:length(x))) {
  executeOnMultipleDataSources(x[[i]])
}
# 
# # launch cohort explorer
# for (i in (1:length(x))) {
#   cohortTableName <- paste0(
#     stringr::str_squish(x$databaseId),
#     stringr::str_squish("SkeletonCohortDiagnosticsStudy")
#   )
#   # Details for connecting to the server:
#   connectionDetails <-
#     DatabaseConnector::createConnectionDetails(
#       dbms = x$cdmSource$dbms,
#       server = x$cdmSource$server,
#       user = keyring::key_get(service = x$userService),
#       password =  keyring::key_get(service = x$passwordService),
#       port = x$cdmSource$port
#     )
#   cdmDatabaseSchema <- x$cdmSource$cdmDatabaseSchema
#   cohortDatabaseSchema <- x$cdmSource$cohortDatabaseSchema
#   CohortDiagnostics::launchCohortExplorer(connectionDetails = connectionDetails,
#                                           cdmDatabaseSchema = cdmDatabaseSchema,
#                                           cohortDatabaseSchema = cohortDatabaseSchema,
#                                           cohortTable = cohortTable, 
#                                           cohortId = -1
#   )
# }
# 
# 