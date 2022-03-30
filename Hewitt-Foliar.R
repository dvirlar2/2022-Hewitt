# Dataset Submission Processing for Hewitt's Foliar Data
# March 16


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
packageId <- "resource_map_urn:uuid:da9966b1-9938-4c4a-bd9e-538c61b5f776"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


# Get the metadata id
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")
xml


# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))



## -- data processing -- ##
# Change otherEntity to dataTable
doc <- eml_otherEntity_to_dataTable(doc, 1, validate_eml = F)
eml_validate(doc)
# TRUE


# Add physical to .csv file
csv_pid <- selectMember(dp, name = "sysmeta@fileName", value = ".csv")
csv_phys <- pid_to_eml_physical(d1c@mn, csv_pid)

doc$dataset$dataTable[[1]]$physical <- csv_phys
eml_validate(doc)
# TRUE

# add FAIR data practices
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)
eml_validate(doc)
# TRUE


## -- publish/update package -- ##
eml_path <- "~/Scratch/Foliar_nutrients_and_natural_abundance_isotope.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)

# public argument has bug in it, and package is being set to public. 
PackageId <- arcticdatautils::remove_public_read(d1c@mn, xml)


## ------------------ set rights & access ------------------- ##
# Rebecca Hewitt doesn't have access, so adding her back
# Manually set ORCiD

# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0002-6668-8472'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, packageId)

# metadata pids
pids_all <- get_all_versions(d1c@mn, pids$metadata)
set_rights_and_access(d1c@mn, pids_all, subject = subject,
                      permissions = c('read', 'write', 'changePermission'))

# csv pids
pids_all <- get_all_versions(d1c@mn, pids$data)
set_rights_and_access(d1c@mn, pids_all, subject = subject,
                      permissions = c('read', 'write', 'changePermission'))

# resource pids
pids_all <- get_all_versions(d1c@mn, pids$resource_map)
set_rights_and_access(d1c@mn, pids_all, subject = subject,
                      permissions = c('read', 'write', 'changePermission'))


eml_validate(doc)



## ------------------ publish/update package ------------------- ##
eml_path <- "~/Scratch/Foliar_nutrients_and_natural_abundance_isotope.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)



# --------------------------------------------------------------- # 
# Remove the "These are raw data and analysis is in the process" annotation
# for the whole data set. 

doc$dataset$additionalInfo <- NULL
eml_validate(doc)




## -- fix funding section -- ##
awards <- c("1545558", "1708344")
proj <- eml_nsf_to_project(awards, eml_version = "2.2.0")

doc$dataset$project <- proj
eml_validate(doc)


## -- add discipline categorization -- ## 
doc <- eml_categorize_dataset(doc, c("Plant Science", "Ecology", "Biochemistry"))



## -- publish with DOI -- ## 
# Write EML
eml_path <- "~/Scratch/Foliar_nutrients_and_natural_abundance_isotope.xml"
write_eml(doc, eml_path)

# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

# publish doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public=TRUE, quiet=FALSE)
