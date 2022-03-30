# Hewitt Tree Density Submission
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
packageId <- "resource_map_urn:uuid:b57b3f08-7bdc-4458-a617-430510892b72"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


# Get the metadata id
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")
xml

# Get data id
csv <- selectMember(dp, name = "sysmeta@fileName", value = ".csv")

# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- set rights & access -- ##
# Rebecca Hewitt doesn't have access, so adding her back
# Manually set ORCiD
subject <- 'http://orcid.org/0000-0002-6668-8472'


set_rights_and_access(d1c@mn,
                      pids = c(xml, csv, packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))

eml_validate(doc)


## -- publish/update package -- ##
eml_path <- "~/Scratch/Tree_Density.xml"
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
eml_path <- "~/Scratch/Tree_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)



## -- add discipline categorization -- ## 
doc <- eml_categorize_dataset(doc, c("Plant Science", "Ecology", "Biochemistry"))


## -- fix funding section -- ##
awards <- c("1545558", "1708344", "1304040", "1708307")
proj <- eml_nsf_to_project(awards, eml_version = "2.2.0")

doc$dataset$project <- proj
eml_validate(doc)



## -- add discipline categorization -- ## 
doc <- eml_categorize_dataset(doc, c("Plant Science", "Ecology", "Biochemistry"))



## -- fix methods and abstract -- ##
doc$dataset$abstract$para[1] <- "We characterized tree-level aboveground C and N cycling metrics in 26 stands across a tree density gradient of monodominant Cajander larch (Larix cajanderi) at the taiga-tundra ecotone in far northeastern Siberia. We calculated tree-level metrics (i.e., C, N, and biomass pools, resorption, N uptake, N production, N residence time, N use efficiency). Our calculations are based on inventory data collected from 2010-2017 at the three plots located within each of the 26 stands. In brief, we measured diameter at breast height (≥ 1.4 m tall) or basal diameter (< 1.4 m tall) for each live L. cajanderi tree within each plot (i.e., belt transect with larger area for lower density). Estimates of L. cajanderi aboveground biomass were based on allometric equations and production was based on the 10- year average ring-width measurements obtained from basal cores or disks ~ 30 cm above the forest floor from five to 10 trees per stand. Our calculation of C and N cycling metrics are based on these biomass and productivity values for individual trees and measurements of C and N content of tree tissues."

doc$dataset$methods$sampling$samplingDescription[1] <- "We sampled vegetation parameters in three plots located at least 30 m apart within each of the 26 stands (each stand ~0.5 ha). Plots consisted of a variable-width, 30-m length belt transect. The width of the belt transect ranged from 1 m wide in the stands with the highest tree density to 8 m wide in the stands with the lowest tree density (Paulson et al. 2021, Walker et al. 2021). In brief, we measured diameter at breast height (≥ 1.4 m tall) or basal diameter (< 1.4 m tall) for each live L. cajanderi tree within each plot (i.e., belt transect with larger area for lower density). Estimates of L. cajanderi aboveground biomass were based on allometric equations and production was based on the 10- year average ring-width measurements obtained from basal cores or disks ~ 30 cm above the forest floor from five to 10 trees per stand. The calculation of C and N cycling metrics are based on these biomass and productivity values for individual trees and measurements of C and N content of tree tissues."


## -- publish/update package -- ##
eml_path <- "~/Scratch/Tree_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)



## -- publish with DOI -- ## 
# Write EML
eml_path <- "~/Scratch/Tree_level_nitrogen_and_carbon_cycling.xml"
write_eml(doc, eml_path)

# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

# publish doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public=TRUE, quiet=FALSE)
