# rdm-covoc_server
*REST backend for JavaScript components from local installation of Dataverse UI*

This repository contains the Ruby source files of the backend for JavaScript UI components as used by the local installation of the Dataverse. For example, this server provides the backend for the author lookup component, implemented as covoc field, and other covoc fields. Furthermore, lookup fields from the Claimer application are served from this backend. For easier deployment, the server is placed in a docker container, with the `Dockerfile` located in the `image` folder.

The term `covoc` refers to `Controlled Vocabulary` loosely interpreted as a finite collection of specific values, preferably identified by an `URI`. More in particular, the Dataverse foresees the `covoc` functionality for the keyword field that can be configured to only accept terms from specific vocabularies, e.g., UNESCO Thesaurus vocabulary. However, this functionality can be extended to any field from Dataverse metadata and the corresponding field values can be controlled by any list and served by any backend with usage of custom JavaScript behind the particular field. Therefore, the main goal of this server is to manage large lists, not suitable for hard-coding in the metadata configuration due to large size or other reasons (e.g., the need for management of the used terms, like in the case of researchers associated with KU Leuven, where management of that list is done by some unrelated to Dataverse application), and source them to the specific `covoc` fields in the Dataverse metadata.

The application contains the following backend implementations (see `config.ru` in `server` folder):
- `/authors`: lookup of the researchers associated with KU Leuven
- `/publications`: lookup of the related publications in Limo service
- `/citation`: Limo provides an excellent index for the lookup. However, it does not contain raw citation data that can be used in metadata. This service retrieves the needed citation data for selected publication from the Lirias service
- `/claimer`: backend for the claimer application accepting metadata of datasets being claimed
- `/openaire/search/datasets`: wrapper around the OpenAire service with added authentication to OpenAire

These services are described in more detail in the sections below.

Additionally, this server hosts the JavaScript as used by the KU Leuven Dataverse installation to implement the UI of the covoc fields controlled by this backend. The script itself is located in the `server/public/js` folder.

The installation is driven by `make`. The `Makefile` covers the daily operations of the application, including building and pushing the docker image.

## Authors
The authors service is based on the personnel list as exported from the PeopleSoft installation and synced every night. This list (in a heavily redacted form) is placed on an FTP server by the PeopleSoft software, where a cron job running on the server hosting the KU Leuven Dataverse installation synchronizes the local representation of that list. The cron job itself, as all the other cron jobs used in the context of the KU Leuven Dataverse installation, is located at the rdm-deployment repository. Furthermore, the synced data is indexed by a Solr server that is also deployed and manage by the scripts on rdm-deployment. This Solr server is shared with the Dataverse installation itself for indexing of the datasets. Finally, the index of the personnel on the Solr server is then used through the Solr interface for the author lookup functionality. In other words, the `/authors` service delegates the lookup work to the Solr server, where the corresponding index is created and maintained as described above.

The scripts for maintaining the author index are located in this repository in the `bin` folder, while all the other scripts, including the creation and deployment of Solr server scripts, are located at the rdm-deployment repository.

The `/authors` service accepts the following query parameters in a `get` request:
- `from`: optional parameter for pagination, indicating from which result row the result list should start. The default value (if not provided) is 0.
- `per_page`: optional parameter for pagination, indicating the number of rows in the result. The default value (if not provided) is 10.
- `q`: required parameter containing the query term. If the term starts with `u` followed by digits, then the search is executed on the personnel (u) number field. If the term contains the `@` sign, the search is executed on the e-mail field. If the term consists only of letters, the search is executed on the name field. In all other cases, the search is executed on all fields.

The results are presented as json. For example, https://www.rdm.libis.kuleuven.be/covoc/authors?q=Keunen&from=0&per_page=10 requests results in (notice the phonetic search capabilities):
```
{
   "numFound":27,
   "start":0,
   "maxScore":232.92049,
   "numFoundExact":true,
   "docs":[
      {
         "uNumber":"U0098658",
         "fullName":"Keunen, Stef",
         "eMail":"stef.keunen@kuleuven.be",
         "affiliation":"Associatie KU Leuven",
         "score":232.92049
      },
      {
         "uNumber":"U0150642",
         "fullName":"Coenen, Indira",
         "eMail":"indira.coenen@kuleuven.be",
         "affiliation":"Associatie KU Leuven",
         "orcid":"0000-0003-4772-0542",
         "score":12.372149
      },
      {
         "uNumber":"U0077146",
         "fullName":"Coenen, Katrien",
         "eMail":"katrien.coenen@kuleuven.be",
         "affiliation":"Associatie KU Leuven",
         "score":12.372149
      },
      {
         "uNumber":"U0077674",
         "fullName":"Coenen, Aimé",
         "eMail":"aime.coenen@ucll.be",
         "affiliation":"Associatie KU Leuven",
         "score":12.372149
      },
      {
         "uNumber":"U0066258",
         "fullName":"Coenen, Sarah",
         "eMail":"sarah.coenen@ucll.be",
         "affiliation":"Associatie KU Leuven",
         "score":12.372149
      },
      {
         "uNumber":"U0108710",
         "fullName":"Coenen, Laurien",
         "eMail":"laurien.coenen@kuleuven.be",
         "affiliation":"Associatie KU Leuven",
         "orcid":"0000-0001-8560-7706",
         "score":12.372149
      },
      {
         "uNumber":"U0101662",
         "fullName":"Coenen, Ena",
         "eMail":"ena.coenen@kuleuven.be",
         "affiliation":"Associatie KU Leuven",
         "orcid":"0000-0002-5189-0280",
         "score":12.372149
      },
      {
         "uNumber":"U0087909",
         "fullName":"Coenen, Emily",
         "eMail":"emily.coenen@kuleuven.be",
         "affiliation":"Associatie KU Leuven",
         "score":12.372149
      },
      {
         "uNumber":"U0092838",
         "fullName":"Coenen, Krishna",
         "eMail":"krishna.coenen@thomasmore.be",
         "affiliation":"Associatie KU Leuven",
         "score":12.372149
      },
      {
         "uNumber":"U0093079",
         "fullName":"Coenen, Lize",
         "eMail":"lize.coenen@kuleuven.be",
         "affiliation":"Associatie KU Leuven",
         "orcid":"0000-0002-5466-3155",
         "score":12.372149
      }
   ],
   "next":10,
   "lirias":"https://lirias2test.libis.kuleuven.be"
}
```

## Publications
This service functions as a proxy to the Limo REST service, which in its turn uses an underlying Solr index. This service, as the name suggests, can be used to lookup related publications when filling metadata in the Dataverse UI. All publications registered in Lirias can be found through this service. Because of the underlying technology and technical functionality that is very similar to the authors service, the query parameters of the publications service are very similar to the ones from the author service:
- `from`: optional parameter for pagination, indicating from which result row the result list should start. The default value (if not provided) is 0.
- `per_page`: optional parameter for pagination, indicating the number of rows in the result. The default value (if not provided) is 10.
- `q`: required parameter containing the query term. If the term contains only digits, then the search is executed on the Lirias ID field. If the term starts with `u` followed by digits, then the search is executed on the personnel (u) number of the author. If the term starts with the `@` sign, the search is executed on the author name field of the publication. In all other cases, the search is executed on all fields, including the title.

Furthermore, the responses are very similar to the ones from the author service. For example, a get request to https://www.rdm.libis.kuleuven.be/covoc/publications?q=@keunen&from=0&per_page=10 results in:
```
{
   "numFound":37,
   "start":1,
   "docs":[
      {
         "id":"2042350",
         "title":"Simultaneous use of low methylesterified citrus pectin and EDTA as antioxidants in linseed/sunflower oil-in-water emulsions",
         "citation":"Celus, Miete ; Kyomugasho, Clare ; Keunen, Julie ; Van Loey, Ann M ; Grauwet, Tara ; Hendrickx, Marc E. &quot;Simultaneous use of low methylesterified citrus pectin and EDTA as antioxidants in linseed/sunflower oil-in-water emulsions.&quot; Food Hydrocolloids; 2020; Vol. 100; pp. -",
         "link":"https://lirias.q.icts.kuleuven.be/2042350",
         "doi":"10.1016/j.foodhyd.2019.105386",
         "issn":"0268-005X; ",
         "url":"https://doi.org/10.1016/j.foodhyd.2019.105386"
      },
      {
         "id":"2046569",
         "title":"EIA-driven biodiversity mainstreaming in development cooperation: Confronting expectations and practice in the DR Congo",
         "citation":"Huge, Jean ; de Bisthoven, Luc Janssens ; Mushiete, Mathilda ; Rochette, Anne-Julie ; Candido, Soraya ; Keunen, Hilde ; Dandouh-Guebas, Farid ; Koedam, Nico ; Vanhove, Maarten PM. &quot;EIA-driven biodiversity mainstreaming in development cooperation: Confronting expectations and practice in the DR Congo.&quot; Environmental Science & Policy; 2020; Vol. 104; pp. 107 - 120",
         "link":"https://lirias.q.icts.kuleuven.be/2046569",
         "doi":"10.1016/j.envsci.2019.11.003",
         "issn":"1462-9011; ",
         "url":"https://doi.org/10.1016/j.envsci.2019.11.003"
      },
      {
         "id":"1687821",
         "title":"Risk stratification during ED nurse triage for patients with transient loss of consciousness: a pilot study",
         "citation":"Vanbrabant, Peter ; Hombroux, L ; Keunen, S ; Gregoire, N ; Crijns, Petra ; Verelst, Sandra. &quot;Risk stratification during ED nurse triage for patients with transient loss of consciousness: a pilot study.&quot; BeSEDiM Annual Symposium 2017 Abstract Book; 2017",
         "link":"https://lirias.q.icts.kuleuven.be/1687821"
      },
      {
         "id":"1554434",
         "title":"A Case of Primary Aortoenteric Fistula: Review of Therapeutic Challenges.",
         "citation":"Keunen, Bram ; Houthoofd, Sabrina ; Daenens, Kim ; Hendriks, Jeroen ; Fourneau, Inge. &quot;A Case of Primary Aortoenteric Fistula: Review of Therapeutic Challenges..&quot; Ann Vasc Surg; 2016; Vol. 33; pp. 230.e5 - 230.e13",
         "link":"https://lirias.q.icts.kuleuven.be/1554434",
         "doi":"10.1016/j.avsg.2015.11.033",
         "issn":"0890-5096; ",
         "url":"https://doi.org/10.1016/j.avsg.2015.11.033"
      },
      {
         "id":"1629389",
         "title":"Urgent need for better education: example of maternal dyspnea in a twin pregnancy",
         "citation":"Baud, David ; Van Mieghem, Tim ; Windrim, Rory ; Raio, Luigi ; Keunen, Johannes ; Ryan, Greg. &quot;Urgent need for better education: example of maternal dyspnea in a twin pregnancy.&quot; Prenatal diagnosis; 2014; Vol. 34; iss. 11; pp. 1119 - 22",
         "link":"https://lirias.q.icts.kuleuven.be/1629389",
         "doi":"10.1002/pd.4437",
         "issn":"0197-3851; ",
         "url":"https://doi.org/10.1002/pd.4437"
      },
      {
         "id":"1897978",
         "title":"Twin-twin transfusion syndrome (TTTS): a frequently missed diagnosis with important consequences",
         "citation":"Baud, D ; Windrim, R ; Van Mieghem, Tim ; Keunen, H ; Van Seaward, G ; Ryan, G. &quot;Twin-twin transfusion syndrome (TTTS): a frequently missed diagnosis with important consequences.&quot; Ultrasound in Obstetrics & Gynecology; 2014; Vol. 44; iss. 2; pp. 205 - 9",
         "link":"https://lirias.q.icts.kuleuven.be/1897978",
         "issn":"0960-7692; "
      },
      {
         "id":"1785263",
         "title":"Espace, temps et récit: imagination narrative et urbanisme",
         "citation":"Keunen, Bart ; Uytenhove, Pieter ; Van Nuijs, Laurence. &quot;Espace, temps et récit: imagination narrative et urbanisme.&quot; Architecture et littérature: une interaction en question XXème-XXIème siècles; 2014; pp. 105 - 115",
         "link":"https://lirias.q.icts.kuleuven.be/1785263"
      },
      {
         "id":"792567",
         "title":"Plant sugars are crucial players in the oxidative challenge during abiotic stress. Extending the traditional concept",
         "citation":"Keunen, Els ; Peshev, Darin ; Vangronsveld, Jaco ; Van den Ende, Wim ; Cuypers, Ann. &quot;Plant sugars are crucial players in the oxidative challenge during abiotic stress. Extending the traditional concept.&quot; Plant, Cell & Environment; 2013; Vol. 36; iss. 7; pp. 1242 - 1255",
         "link":"https://lirias.q.icts.kuleuven.be/792567",
         "doi":"10.1111/pce.12061",
         "issn":"0140-7791; ",
         "url":"https://doi.org/10.1111/pce.12061"
      },
      {
         "id":"1629580",
         "title":"Minimally invasive surgical management of a second trimester pregnancy in a rudimentary uterine horn",
         "citation":"Lennox, Genevieve ; Pantazi, Sophia ; Keunen, Johannes ; Van Mieghem, Tim ; Allen, Lisa. &quot;Minimally invasive surgical management of a second trimester pregnancy in a rudimentary uterine horn.&quot; Journal of Obstetrics and Gynaecology Canada; 2013; Vol. 35; iss. 5; pp. 468 - 72",
         "link":"https://lirias.q.icts.kuleuven.be/1629580",
         "doi":"10.1016/S1701-2163(15)30938-5",
         "issn":"1701-2163",
         "url":"https://doi.org/10.1016/S1701-2163(15)30938-5"
      },
      {
         "id":"1712574",
         "title":"Heeft bosfragmentatie een effect op de autecologie van de dominante boomsoorten in de Taita Hills (Kenia)?",
         "citation":"Keunen, Stien ; Thijs, Koen ; Musila, Winnie ; Muys, Bart. &quot;Heeft bosfragmentatie een effect op de autecologie van de dominante boomsoorten in de Taita Hills (Kenia)?.&quot; ",
         "link":"https://lirias.q.icts.kuleuven.be/1712574"
      }
   ],
   "next":11
}
```

## Citation
As can be seen in the example from the publications service, the responses already contain a citation field. However, because of the formatting and presence of the escaped html characters, it is not suitable for the citation field in the metadata. In order to counter this, a Lirias service is used to retrieve better formatted citation. Notice that we do not use the Lirias service directly for the lookup of a publication, but we use the index in Solr as provided via Limo interface, as this is better suited for such task. Once we have a result from Limo, it contains the `id` field that reference the Lirias id. We can then easily retrieve the citation field of a specific publication using that id through the Lirias service.

For example, a get request to https://www.rdm.libis.kuleuven.be/covoc/citation?id=1712574 results in:
```
{
    "citation": "Keunen, S., Thijs, K., Musila, W., Muys, B. (2013). Heeft bosfragmentatie een effect op de autecologie van de dominante boomsoorten in de Taita Hills (Kenia)? Presented at the Studiedag Starters in Bosonderzoek, Agency for Nature and Forest, Brussels (Belgium), 15 Mar 2013-15 Mar 2013. ",
    "status": 200
}
```

Notice that the resulting citation is quite different from the citation in the example from publications service:
```
{
    "id":"1712574",
    "title":"Heeft bosfragmentatie een effect op de autecologie van de dominante boomsoorten in de Taita Hills (Kenia)?",
    "citation":"Keunen, Stien ; Thijs, Koen ; Musila, Winnie ; Muys, Bart. &quot;Heeft bosfragmentatie een effect op de autecologie van de dominante boomsoorten in de Taita Hills (Kenia)?.&quot; ",
    "link":"https://lirias.q.icts.kuleuven.be/1712574"
}
```

## Claimer
This service accepts data from the Claimer application. Claimer application lets users lookup datasets published elswere (not in KU Leuven Dataverse) and register the corresponding metadata. Metadata itself is prefetched from either DataCite, or if not present there, from OpenAire services, and can be modified and completed by the users before claiming. The frontend (HTML, JavaScript and CSS code) is deployed on the Apache proxy server with standard deployment scripts as can be found in rdm-deployment repository. That repository also contains the source code of the frontend.

The Claimer service stores the metadata as claimed in the Claimer application on the file system in the data folder mounted to the covoc server at `/data/tools/data/dataVerse/claimer` path (next to the `/data/tools/data/dataVerse/export` files as exported from the Dataverse installation) for nightly import to Lirias. The nightly import to Lirias is a cron job (see rdm-deployment repository) that works in two steps:
- First, the metadata of newly registered datasets is exported from the Dataverse installation with help of Ruby code that can be found in the rdmRbTools repository
- In the second step, metadata from the dataverse as well as metadata registered with the Claimer application using the Claimer service described in this section is imported to Lirias with the use of Python code as can be found in the rdmPyTools repository.

The Claimer service accpets post request with the body containing the json format of metadata. The service itself is protected by the Shibboleth settings in the Apache proxy service from the rdm-deployment repository. This ensures that only authenticated users (having the right to claim the datasets) can post messages to this service. The post request itself is done from within the JavaScript implementation of the Claimer frontend. An example of correctly formatted json metadata as accepted by the Claimer service can be found below:
```
{
    "id": "10.5061/dryad.5k3t47p0",
    "idType": "doi",
    "author": [
        {
            "name": "Floudas, Dimitrios",
            "u": null
        },
        {
            "name": "Binder, Manfred",
            "u": null
        },
        {
            "name": "Benoit, Isabelle",
            "u": "U0000202"
        },
        {
            "name": "Bloemen, Dieuwertje",
            "u": "U0137635"
        }
    ],
    "keyword": [
        "Ascomycota",
        "Auriculariales",
        "Hymenochaetales",
        "white rot",
        "carbon cycle",
        "Gloeophyllales",
        "Basidiomycota",
        "class II peroxidases",
        "Tree Reconciliation",
        "Corticiales",
        "molecular clocks",
        "Cryogenian to present",
        "Polyporales",
        "Russulales",
        "Boletales",
        "Dikarya",
        "Agaricomycotina",
        "Agaricomycetes",
        "wood decay enzymes",
        "ligninolytic enzymes",
        "Agaricales"
    ],
    "relatedPublication": [
        "LIRIAS2197080"
    ],
    "title": "Data from: The Paleozoic origin of enzymatic lignin decomposition reconstructed from 31 fungal genomes",
    "description": "Wood is a major pool of organic carbon that is highly resistant to decay, owing largely to the presence of lignin. The only organisms capable of substantial lignin decay are white rot fungi in the Agaricomycetes, which also contains non–lignin-degrading brown rot and ectomycorrhizal species. Comparative analyses of 31 fungal genomes (12 generated for this study) suggest that lignin-degrading peroxidases expanded in the lineage leading to the ancestor of the Agaricomycetes, which is reconstructed as a white rot species, and then contracted in parallel lineages leading to brown rot and mycorrhizal species. Molecular clock analyses suggest that the origin of lignin degradation might have coincided with the sharp decrease in the rate of organic carbon burial around the end of the Carboniferous period.",
    "technicalFormat": [
        "txt",
        "tsv"
    ],
    "publisher": "Dryad",
    "accessRights": "EMBARGOED",
    "endOfEmbargo": "2012-04-09",
    "optOut": "ethical aspects",
    "license": "CC0-1.0",
    "publicationDate": "2012-04-09",
    "affiliation": "false"
}
```

## OpenAire
This service is also used by the Claimer application and is protected by Shibboleth settings in Apache proxy server, just as the Claimer service is. However, OpenAire service is a simple forwarding proxy to the original OpenAire datasets service. It is called the same way as the original OpenAire service, where the documentation can be found at the OpenAire website: https://graph.openaire.eu/develop/basic.html.

The sole reason for implementing this service is the calls limit for anonymous access to the OpenAire service. This serfvice adds then the authentication to the OpenAire service while forwarding the client calls. Therefore, this OpenAire service implementation needs authentication configuration with account data to function properly. This information is stored in the credentials file, which location is contained in the environment variable `OPEN_AIRE_CREDS_FILE`. The file containing the account of KU Leuven is already installed at the corresponding locations of the RDM servers. In order to use this service locally, you either need to copy the corresponding file or use your own account.

## Requirements and configuration
By using Docker containers and deploying the components as Docker containers, we avoid installing most of the requirements for the individual components of the application. But this deployment and the installation tools do pose some requirements on the machine that this is installed on. Let's summarize:

### Docker
Obviously, Docker needs to be installed. Version 20.10.5 is used at the time of this writing, but any version more recent or not that much older should probably do the trick. The user that will be used for the installation (please do not use root) should be able to access Docker. Usually it is sufficient to make the user part of the `docker` user group.

The LIBIS Docker registry is used to store the images, except in dev mode where the images are expected to be built locally. The Docker registry is defined in the .env file if there ever is a need to change it. It may be necessary to configure your local installation to deal with the LIBIS Docker registry for authentication.

To deploy this server in the context of KU Leuven Dataverse installation, use the scripts from the rdm-deployment repository by following the documentation contained in that repository.

### Make commands
The available tasks:

- `build`: Update and build the Docker image
- `push`: Push Docker image (only in prod stage) to LIBIS Docker Repository
- `update`: Update the script files in the image folder such that a new version of the service can be built (this step is already inculded in the built task)
- `run`: Run the server locally directly with Ruby, without the deployment of the docker image (you need properly configured Ruby environment for that)

Additional tasks that use the underlying scirpts in the `bin` folder are preferably not run directly. A better option is to use the make tasks as provided in the `initialize.mak` portion of the make in the rdm-deployment. Nevertheless, the following tasks are also present in the make file of the covoc server (notice that you need to configure `.env` file with environment variables required by the scripts and otherwise already provided by scripts in rdm-deployment repository):
- `covoc_drop`: Drop the authors index on the configured Solr server
- `covoc_create`: Create the authors index on a Solr server
- `covoc_load`: Load the authors index on the Solr server
- `covoc_config`: Run configuration script for the author index on the Solr server
- `covoc_recreate`: Drop the current author index, create new index and load it. Do this after changes to the index or to manually reload the index from a person's file.

### Environment variables
User and group ID variables. These variables ensure that the processes in the containers will be running with the same IDs as the user on the host, which makes it far easier to access the files that will be stored on the host (e.g. configuration and log files):
- USER_ID : user id of the user running the installation
- GROUP_ID : group id of the user running the installation

These environment variables are automatically set in the Makefile from the rdm-deployment directory. If not using `make`, you may have to set the variables yourself. You would also need to set variables for URL's, secrets, etc. as provided by the `docker-compose.yml`:

```
    environment:
      TZ: "Europe/Brussels"
      SOLR_HOST: http://index:8983
      LIMO_HOST: limo.q.libis.be
      LIRIAS_HOST: https://lirias2test.libis.kuleuven.be
      INDEX_DATA_DIR: /index/data
      DATA_DIR: /data
      LOG_LEVEL: error
      OPEN_AIRE_CREDS_FILE: "/run/secrets/openaire/oa_creds"
```

Notice that the `docker-compose.yml` also provides other needed configuration for the services to run correctly, e.g., the volumes as required by the services. Therefore, running the scripts in the rdm-deployment repository remains the preferred way to run and maintain the covoc server.
