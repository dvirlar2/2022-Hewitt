# Daphne Virlar-Knight
# March 23, 2022

# Dataset: https://arcticdata.io/catalog/view/urn%3Auuid%3Abd4d5f16-c2d7-46c2-b07f-dcbdf15f4cbf




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
packageId <- "resource_map_urn:uuid:503b53d2-6bd2-4762-a9c2-6965d93a33f3"
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


# Add Nat Geo Award
eml_award <- eml$award()
eml_award$funderName <- "National Geographic Society"
eml_award$awardNumber <- "9935-16"
eml_award$title <- "Plant acquisition of deep nitrogen and the permafrost carbon feedback to climate"

doc$dataset$project$award[[5]] <- eml_award
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
doc <- eml_categorize_dataset(doc, c("Plant Science", "Ecology", "Biochemistry"))


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
eml_path <- "~/Scratch/Root_tissue_chemistry_mycorrhizal_colonization_.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)


## -- fix categories -- ##
# I think I ran the above categories twice, and so it doubled up the annotations.
# woops
doc$dataset$annotation <- list(doc$dataset$annotation[[1]],
                            doc$dataset$annotation[[2]],
                            doc$dataset$annotation[[3]],
                            doc$dataset$annotation[[4]])



## -- set rights & access -- ##
# Rebecca Hewitt doesn't have access, so adding her back

# Manually set ORCiD
subject <- 'http://orcid.org/0000-0002-6668-8472'


# trying to find all pids to see where becky lost access
pids <- get_package(d1c@mn, packageId)

pids_all <- get_all_versions(d1c@mn, pids$metadata) #all metadata pids
set_rights_and_access(d1c@mn, pids_all, subject = subject)
# urn:uuid:4388fbf1-6a0c-4521-ace8-23b1d480f5f4 
# TRUE
# urn:uuid:d0374009-2c48-427d-b39d-d283a34276d6 
# TRUE
# urn:uuid:3ff0a001-89b1-4eab-bdbd-00fe217146dd 
# TRUE
# urn:uuid:bd4d5f16-c2d7-46c2-b07f-dcbdf15f4cbf 
# TRUE
# urn:uuid:3e0915aa-67ff-4b3b-adcb-d500846a3d02 
# TRUE
# urn:uuid:437ab37b-db99-4fae-8c2d-da38c159c41c 
# TRUE


rm_pids_all <- get_all_versions(d1c@mn, pids$resource_map) #all resource map pids
set_rights_and_access(d1c@mn, rm_pids_all, subject = subject)
# resource_map_urn:uuid:e0d2ec05-6619-49b2-976e-7d105fdd361e 
# TRUE 
# resource_map_urn:uuid:ab235779-a1cc-4b9d-b88c-2917c11a7f4a 
# TRUE 
# resource_map_urn:uuid:bdfcd2fe-3b82-4b5f-ab4b-7d57d5e988a3 
# TRUE 
# resource_map_urn:uuid:1400dce7-7c7b-4960-8d39-cb90ddd7f997 
# TRUE 
# resource_map_urn:uuid:3e0915aa-67ff-4b3b-adcb-d500846a3d02 
# TRUE 
# resource_map_urn:uuid:437ab37b-db99-4fae-8c2d-da38c159c41c 
# TRUE 


csv_pids_all <- get_all_versions(d1c@mn, pids$data) #all csv map pids
set_rights_and_access(d1c@mn, csv_pids_all, subject = subject)
# urn:uuid:921e29d4-b67f-43cc-a39e-da6d75bb7b7d 
# TRUE 


## -- fix abstracts and methods -- ##
doc$dataset$methods$sampling$studyExtent$description$para[1] <- "We conducted our research in the larch forests around the Northeast Science Station (NESS, 68.74° N, 161.40° E) in northeastern Siberia close to Cherskiy, Sakha Republic, Russian Federation. The NESS is located on the Kolyma River, ~ 250 km north of the Arctic Circle and ~ 130 km south of the Arctic Ocean. Forests in this region of the Russian Far East are typically open-canopied, sparse stands dominated by L. cajanderi  (Alexander et al., 2018, Alexander et al., 2012, Berner et al., 2012), a deciduous needleleaf conifer, which grows in habitats with continuous permafrost (Abaimov, 2010). Trees in this region are short in stature, generally < 10 m tall, and stands have relatively low aboveground biomass compared to more southern stands (Berner et al., 2012). We sampled larch roots from 10 stands across the density gradient in September 2017."

doc$dataset$methods$methodStep[[2]]$description$para[1] <- "In the lab, we pooled the six soil samples from each stand by horizon (organic, mineral) and depth increment and processed them as one sample. We sampled fine larch roots (< 2mm in diameter) from each pooled sample, which are easy to identify based on morphology, texture, and coloration. Root segments from organic and upper mineral (0-10 cm) soils were gently washed, cut into 2-4 cm segments, and divided into five subsamples equivalent to approximately 0.2 g dry mass: four for N uptake incubations and one for mycorrhizal colonization and molecular characterization of the fungal community. Root biomass in the 10-20 cm mineral depth increment was minimal, and thus, excluded from the N uptake study for all but two stands, which had sufficient biomass for analyses (> 0.003 g cm-3). In total, there were five subsamples [natural abundance, glycine, ammonium, nitrate, mycorrhizal] x 2 soil horizons [organic, 0-10 cm mineral] x 10 stands, plus comparable subsamples from the 10-20 cm depth increment for two stands."


## -- publish/update package -- ##
eml_path <- "~/Scratch/Root_tissue_chemistry_mycorrhizal_colonization_.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish
dp <- replaceMember(dp, xml, replacement=eml_path)
PackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)



## -- publish with DOI -- ## 
# Write EML
eml_path <- "~/Scratch/Root_tissue_chemistry_mycorrhizal_colonization_.xml"
write_eml(doc, eml_path)

# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

# publish doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public=TRUE, quiet=FALSE)
