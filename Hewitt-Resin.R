# Daphne Virlar-Knight
# March 23, 2022

# Dataset: https://arcticdata.io/catalog/view/urn:uuid:9e3abec1-a689-4446-99e3-c8225208153e




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
packageId <- "resource_map_urn:uuid:ea0706e0-c160-43eb-978b-ad925a6b64fa"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


# Get the metadata id
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")


# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))



## -- fix funding section -- ##
# Add NSF Awards
awards <- c("1708344", "1545558", "1304040", "1708307")
proj <- eml_nsf_to_project(awards, eml_version = "2.2.0")

doc$dataset$project <- c(proj)
eml_validate(doc)


## -- adjust personnel -- ##
# Make Heathers [[3]] and [[4]] the same
doc$dataset$project$personnel[[3]]$individualName$givenName <- "Heather D."

# add Orcid Id to first Heather
doc$dataset$project$personnel[[3]]$userId <- "https://orcid.org/
0000-0003-1307-8483"

# add directory to Orcid Id
doc$dataset$project$personnel[[3]]$userId$directory <- "https://orcid.org"
doc$dataset$project$personnel[[3]]$userId$userId <- "https://orcid.org/
0000-0003-1307-8483"


# add Orcid Id to second Heather
doc$dataset$project$personnel[[4]]$userId <- "https://orcid.org/
0000-0003-1307-8483"

# add directory to Orcid Id
doc$dataset$project$personnel[[4]]$userId$directory <- "https://orcid.org"
doc$dataset$project$personnel[[4]]$userId$userId <- "https://orcid.org/
0000-0003-1307-8483"

eml_validate(doc)



## -- add discipline categorization -- ## 
doc <- eml_categorize_dataset(doc, c("Plant Science", "Soil Science", "Ecology", "Biochemistry"))


## -- otherEntity to dataTable -- ##
doc <- eml_otherEntity_to_dataTable(doc, 1, validate_eml = F)
eml_validate(doc)


## -- create physicals -- ##
csv_pid <- selectMember(dp, name = "sysmeta@fileName", value = ".csv")
csv_phys <- pid_to_eml_physical(d1c@mn, csv_pid)

doc$dataset$dataTable[[1]]$physical <- csv_phys
eml_validate(doc)


## -- add FAIR protocols -- ##
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)
eml_validate(doc)


## -- publish/update package -- ##
eml_path <- "~/Scratch/Resin_sorbed_nitrate_and_ammonium_in_organic_and.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)


## -- fix methods and abstract -- ##
doc$dataset$abstract$para <- "We quantified nitrate (NO3-) and ammonium (NH4+) availability in organic and mineral soils in the field using mixed-bed ion exchange resins across a tree density gradient near the Northeast Science Station, Russia, 2015-2016. This data set consists of resin-sorbed NO3- and NH4+ expressed in mg N yr-1."


doc$dataset$methods$sampling$studyExtent$description$para[[1]] <- "We conducted our research in the larch forests around the Northeast Science Station (NESS, 68.74° N, 161.40° E) in northeastern Siberia close to Cherskiy, Sakha Republic, Russian Federation. The NESS is located on the Kolyma River, ~ 250 km north of the Arctic Circle and ~ 130 km south of the Arctic Ocean. Forests in this region of the Russian Far East are typically open-canopied, sparse stands dominated by L. cajanderi (Alexander et al., 2018, Alexander et al., 2012, Berner et al., 2012), a deciduous needleleaf conifer, which grows in habitats with continuous permafrost (Abaimov, 2010). Trees in this region are short in stature, generally < 10 m tall, and stands have relatively low aboveground biomass compared to more southern stands (Berner et al., 2012)."


## -- publish/update package -- ##
eml_path <- "~/Scratch/Resin_sorbed_nitrate_and_ammonium_in_organic_and.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)




## -- set rights & access -- ##
# Rebecca Hewitt doesn't have access, so adding her back

# Manually set ORCiD
subject <- 'http://orcid.org/0000-0002-6668-8472'


# trying to find all pids to see where becky lost access
pids <- get_package(d1c@mn, packageId)

pids_all <- get_all_versions(d1c@mn, pids$metadata) #all metadata pids
set_rights_and_access(d1c@mn, pids_all, subject = subject)
# all true


rm_pids_all <- get_all_versions(d1c@mn, pids$resource_map) #all resource map pids
set_rights_and_access(d1c@mn, rm_pids_all, subject = subject)
# all true

csv_pids_all <- get_all_versions(d1c@mn, pids$data) #all csv map pids
set_rights_and_access(d1c@mn, csv_pids_all, subject = subject)
# all true


## -- publish with DOI -- ## 
# Write EML
eml_path <- "~/Scratch/Resin_sorbed_nitrate_and_ammonium_in_organic_and.xml"
write_eml(doc, eml_path)

# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

# publish doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public=TRUE, quiet=FALSE)
