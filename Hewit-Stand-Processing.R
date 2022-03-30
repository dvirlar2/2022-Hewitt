# Initial Processing/Wrangling
# March 14 2022



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
packageId <- "resource_map_urn:uuid:0c271276-430c-4494-818f-5d77781b261b"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


# Get the metadata id
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")


# Get the csv id
csv <- selectMember(dp, name = "sysmeta@fileName", value = ".csv")


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


## --------------------- ## 
# Process the data itself
# March 16


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
eml_path <- "~/Scratch/Stand_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)


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
eml_path <- "~/Scratch/Stand_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)



# ------------------------------------------------------------- #
# PI added file with incorrect header and definitions. 
# Added correct file via GUI. Going to copy over attributes
# Publish the package, and then remove the "wrong" file on the GUI

# Assign reference attributes
attList <- doc$dataset$dataTable$attributeList

# Create reference id
doc$dataset$dataTable$attributeList$id <- "reference attributes"


# Assign reference to "correct" csv
doc$dataset$otherEntity$attributeList <- attList
doc$dataset$otherEntity$attributeList <- list(references = "reference attributes")

eml_validate(doc)


## -- add discipline categorization -- ## 
doc <- eml_categorize_dataset(doc, c("Plant Science", "Ecology", "Biochemistry"))


## -- update dataset -- ##
eml_path <- "~/Scratch/Stand_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)


## -- fix abstract and methods -- ##
doc$dataset$abstract$para[1] <- "We characterized stand-level aboveground C and N cycling metrics in 26 stands across a tree density gradient of monodominant Cajander larch (Larix cajanderi) at the taiga-tundra ecotone in far northeastern Siberia. We calculated stand-level characteristics (i.e., C, N, and biomass pools, resorption, N uptake, N production, N residence time, N use efficiency). Our calculations are based on inventory data collected from 2010-2017 at the three plots located within each of the 26 stands. In brief, we measured diameter at breast height (≥ 1.4 m tall) or basal diameter (< 1.4 m tall) for each live L. cajanderi tree within each plot (i.e., belt transect with larger area for lower density). Estimates of L. cajanderi aboveground biomass were based on allometric equations and production was based on the 10- year average ring-width measurements obtained from basal cores or disks ~ 30 cm above the forest floor from five to 10 trees per stand. Our calculation of C and N cycling metrics are based on these biomass and productivity values for individual trees and measurements of C and N content of tree tissues. We calculated stand-level metrics by summing the tree-level pool estimates for each stand."

doc$dataset$methods$sampling$samplingDescription$para[1] <- "We sampled vegetation parameters in three plots located at least 30 m apart within each of the 26 stands (each stand ~0.5 ha). Plots consisted of a variable-width, 30-m length belt transect. The width of the belt transect ranged from 1 m wide in the stands with the highest tree density to 8 m wide in the stands with the lowest tree density (Paulson et al. 2021, Walker et al. 2021). In brief, we measured diameter at breast height (≥ 1.4 m tall) or basal diameter (< 1.4 m tall) for each live L. cajanderi tree within each plot (i.e., belt transect with larger area for lower density). Estimates of L. cajanderi aboveground biomass were based on allometric equations and production was based on the 10- year average ring-width measurements obtained from basal cores or disks ~ 30 cm above the forest floor from five to 10 trees per stand."


## -- publish/update dataset -- ##
eml_path <- "~/Scratch/Stand_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)



## -- remove alternate identifiers -- ##
doc$dataset$alternateIdentifier <- NULL



## -- publish with DOI -- ## 
# Write EML
eml_path <- "~/Scratch/Stand_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)

# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

# publish doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public=TRUE, quiet=FALSE)
