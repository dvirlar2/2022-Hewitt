# Initial Processing/Wrangling
# March 14 2022

# ul: https://arcticdata.io/catalog/view/urn%3Auuid%3A4ecfe951-8d46-4d1a-aa7c-ea313058e4db
# resource map: resource_map_urn:uuid:3a0c5a9d-cce2-44a5-93a7-b26bf520e348

# Purpose of this ticket is to look and see if I can fix the personnel issue in
# Becky Hewitt's data submission

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- read in data -- ##
# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")


# Get the package
packageId <- "resource_map_urn:uuid:cb4b2982-f89b-4786-b4a5-bf421d97b6ef"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


# Get the metadata id
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")
xml # "urn:uuid:6dd64b06-ec39-4a64-a0f5-f0df0c8f8545"


# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- fix personnel layout on the landing page -- ##
awards <- c("1545558", "1708344", "1304040", "1708307", "1304007", "1304464", "1623764")
proj <- eml_nsf_to_project(awards, eml_version = "2.2.0")

doc$dataset$project <- proj
eml_validate(doc)
  # TRUE

# Make Heather's names the same, and add Orcid Ids
doc$dataset$project$personnel[[4]]$individualName$givenName <- "Heather D"

# add Orcid Id to first Heather
doc$dataset$project$personnel[[4]]$userId <- "https://orcid.org/
0000-0003-1307-8483"

# add directory to Orcid Id
doc$dataset$project$personnel[[4]]$userId$directory <- "https://orcid.org"
doc$dataset$project$personnel[[4]]$userId$userId <- "https://orcid.org/
0000-0003-1307-8483"

# add Orcid Id to second Heather
doc$dataset$project$personnel[[5]]$userId <- "https://orcid.org/
0000-0003-1307-8483"

# add directory to Orcid Id
doc$dataset$project$personnel[[5]]$userId$directory <- "https://orcid.org"
doc$dataset$project$personnel[[5]]$userId$userId <- "https://orcid.org/
0000-0003-1307-8483"


eml_validate(doc)
  # TRUE

## -- publish/update package -- ##
eml_path <- "~/Scratch/Stand-level nitrogen and carbon cycling characteristics of larch forests across a tree density gradient in northeastern Siberia, 2010-2017. .xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)


