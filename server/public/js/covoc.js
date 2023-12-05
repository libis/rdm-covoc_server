/************************************************************************************************************
 * This JavaScript is responsible for the controlled vocabulary features in the browser.                    *
 * The search button opens a dialog in which the controlled vocabulary server can be queried.               *
 * On each result line, a button allows to copy-and-paste the information automatically in the form fields. *
 * ******************************************************************************************************** *
 * Author: Kris Dekeyser @ KU Leuven (2022). MIT License                                                    *
 ************************************************************************************************************/

/* DOM Element Identfiers
 * **********************
 * person-modal: the modal for the dialog box
 * person-modal-title: the dialog box title
 * person-search-box: field in the dialog where search term can be entered
 * person-search-results: location where the query results will be displayed
 * DOM Classes
 * ***********
 * search_added: class added when a search button has already been added
 */

var personModalId ='person-modal';
var personModalTitle = 'Search for person in KU Leuven';
var personModalPlaceholder = 'Search for name, email address, u-number or ORCID ...';
var personModalHelptext = 
  "Type text to search for names, a number to search for ORCID or 'u' followed by a number to search for u-numbers and hit the Enter key to search. " +
  "Type at least 3 characters per word for a meaningful search and '-' and leading 0's can be omitted. " + 
  "Include a '@' to search for email addresses.";
var personSearchBoxId = 'person-search-box';
var personSearchResultsId = 'person-search-results';
var personElementIdAttribute = 'data-person-element-id';
var personSearchIconText = 'Search in KU Leuven';

// Selector for all the author compound fields
var authorSelector = "#metadata_author";

// Selector for all the contact compound fields
var contactSelector = "#metadata_datasetContact";

var pubModalId = 'publication-modal';
var pubModalTitle = 'Search for publication in Lirias';
var pubModalPlaceholder = 'Search for publication';
var pubModalHelptext = 'Type search term and hit the Enter key to search.';
var pubSearchBoxId = 'publication-search-box';
var pubSearchResultsId = 'publication-search-results';
var pubElementIdAttribute = 'data-publication-element-id';
var pubSearchIconText = 'Search in Lirias';

// Selector for all the publication compound fields
var publicationSelector = "#metadata_publication";

/* The browser will run this code the first time the editor is opened and each time a multiple field instance is 
 * added or removed. This code is reposible for creating the HTML for the dialog box, adding a search button to 
 * the name fields and creating the triggers for initializing the dialog box and the search action itself.
 */
$(document).ready(init)

function init() {

  // Create person search modal
  createModal(personModalId, personModalTitle, personModalPlaceholder, personModalHelptext, 
    personSearchBoxId, personSearchResultsId, personElementIdAttribute, personQuery);

  // Put a search button after each name field
  putSearchIcon(authorSelector, 0, personElementIdAttribute, personModalId, personSearchIconText);

  // Put a search button after each contact name field
  putSearchIcon(contactSelector, 0, personElementIdAttribute, personModalId, personSearchIconText);

  // Create publication search modal
  createModal(pubModalId, pubModalTitle, pubModalPlaceholder, pubModalHelptext,
    pubSearchBoxId, pubSearchResultsId, pubElementIdAttribute, publicationQuery);

  // Put search button after each Lirias ID field
  putSearchIcon(publicationSelector, 3, pubElementIdAttribute, pubModalId, pubSearchIconText);

};

// Generic function to create a serch box
function createModal(id, title, placeholder, helptext, searchBoxId, resultsId, elementIdAttribute, queryFunction) {
  let modal = document.getElementById(id);
  if (!modal) {
    // Create modal dialog
    let dialog = document.createElement('div');
    document.body.appendChild(dialog);
    dialog.outerHTML =
      '<div id="' + id + '" class="modal" tabindex="-1" aria-labelledby="' + id + '-title" role="dialog" style="margin-top: 5rem">' + 
        '<div class="modal-dialog" role="document">' + 
          '<div class="modal-content">' + 
            '<div class="modal-header">' + 
              '<button class="close" type="button" data-dismiss="modal" aria-label="close"><span aria-label="Close">X</span></button>' + 
              '<h5 id="' + id + '-title" class="modal-title">' + title + '</h5>' + 
            '</div>' + 
            '<div class="modal-body">' + 
              '<div style="display: flex;">' + 
                '<input id="' + searchBoxId + '" class="form-control" accesskey="s" type="text" placeholder="' + placeholder + '">' + 
                '<span class="glyphicon glyphicon-question-sign tooltip-icon" style="margin-left: 5px;" ' + 
                      'data-toggle="tooltip" data-placement="auto right" data-original-title="' + helptext + '"></span>' +
              '</div>' +
              '<table id="' + resultsId + '" class="table table-striped table-hover table-condensed" style="margin-top: 10px;"><tbody/></table>' + 
            '</div>' + 
          '</div>' + 
        '</div>' + 
      '</div>';

    // Before modal is opened, pull in the current value of the name input field into the search box and launch a query for that value
    $('#' + id).on('show.bs.modal', function(e) {
      // Get the stored ID of the input field
      let inputID = e.relatedTarget.getAttribute(elementIdAttribute);
      let nameElement = document.getElementById(inputID);
      let searchBox = document.getElementById(searchBoxId);
      if (nameElement.value) {
        // Fill in the input field text in the searchBox ...
        searchBox.value = nameElement.value;
        // ... and launch a query
        queryFunction(0);
      }
      // Let the searchBox know where to write the data
      searchBox.setAttribute(elementIdAttribute, inputID);
    });

    // After model is opened, set focus on search box
    $('#' + id).on('shown.bs.modal', function(e) {
      // autofocus does not work with BS modal
      let searchBox = document.getElementById(searchBoxId);
      searchBox.focus();
      searchBox.select();
    });

    // To minimize the load on the lookup service, we opted for an explicit enter to launch a query
    document.getElementById(searchBoxId).addEventListener('keyup', function(e) {
      // Only if Enter key is pressed
      if (e.key === 'Enter') {
        // Launch query with string from searchBox ...
        queryFunction(0);
        // .. and prevent key to be added to the searchBox
        e.preventDefault();
      }
    });
  }
  bind_bsui_components();
}

// Generic function that add a search button to the name input fields
function putSearchIcon(selector, childNr, elementIdAttribute, modalId, searchIconText) {
  // Iterate over compund elements
  let elements = $(selector)?.parent()?.parent()?.find(".dataset-field-values .edit-compound-field");
  for(let i = 0; i < elements?.length; i++) {
    let element = elements[i];
    // 'search_added' class marks elements that have already been processed
    if (!element.classList.contains('search_added')) {
      element.classList.add('search_added');
      // Select child is element that the search box needs to be attachted to
      let metadataField = element.children[childNr];
      // Input field within
      let inputField = metadataField.querySelector('input');
      // We create an bootstrap input group ...
      let wrapper = document.createElement('div');
      wrapper.className = 'input-group';
      wrapper.style.display = 'flex';
      // ... containing the input field ...
      wrapper.appendChild(inputField);
      // ... and a new seach button ...
      let searchButton = document.createElement('button');
      element.setAttribute('aria-describedby', searchButton.id);
      searchButton.className = 'btn btn-default btn-sm bootstrap-button-tooltip compound-field-btn';
      searchButton.setAttribute('type', 'button');
      searchButton.setAttribute('title', searchIconText);
      searchButton.setAttribute('data-toggle', 'modal');
      searchButton.setAttribute('data-target', '#' + modalId);
      searchButton.setAttribute(elementIdAttribute, inputField.id);
      let searchIcon = document.createElement('span');
      searchIcon.className = 'glyphicon glyphicon-search no-text';
      searchButton.appendChild(searchIcon);
      wrapper.appendChild(searchButton);
      // ... and add that to the encapsulating element.
      metadataField.appendChild(wrapper);
    }
  }
}

// Creates a unique id that can be used as element id attribute
function createId() {
	return 'xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxx'.replace(/x/g, function (c) {
	var r = Math.random() * 16 | 0;
	return r.toString(16);
	});
}

// Encode special characters in the string to make them safe to use in HTML
function strEncode(str) {
  if (!str) {
    str = '';
  }
  return str.replace(/&/g, "&amp;")
  .replace(/</g, "&lt;")
  .replace(/>/g, "&gt;")
  .replace(/"/g, "&quot;")
  .replace(/'/g, "&#039;");
}

// Decode string from the encoding in the function above
function strDecode(str) {
  if (!str) {
    str = '';
  }
  return str.replace(/&#039;/g, "'")
  .replace(/&quot;/g, '"')
  .replace(/&gt;/g, ">")
  .replace(/&lt;/g, "<")
  .replace(/&amp;/g, "&");
}

// Generic table header with pagination links
function tableHeader(table, data, queryFunctionName, start) {
  // Add pagination header
  if (data.hasOwnProperty('prev') || data.hasOwnProperty('next')) {
    table.innerHTML += 
    '<tr>' + 
      '<td class="row" colspan="4">' +
        '<div class="col-sm-2">' +
          ((data.hasOwnProperty('prev'))
            ? '<span class="btn btn-default btn-xs pull-left" accesskey="p" onclick="' + queryFunctionName + '(' + data.prev + ')">&lt;&lt;</span>'
            : ''
          ) +
        '</div>' +
        '<div class="col-sm-8 text-center">' +
          (start + 1) + '-' + (start + data.docs.length) + ' of ' + data.numFound +
        '</div>' +
        '<div class="col-sm-2">' +
          ((data.hasOwnProperty('next'))
            ? '<span class="btn btn-default btn-xs pull-right" accesskey="n" onclick="' + queryFunctionName + '(' + data.next + ')">&gt;&gt;</span>'
            : ''
          ) +
        '</div>' +
      '</td>' +
    '</tr>';
  }
}

var page_size = 10; // Number of results that will be displayed on a single page
var searchLoading = '<img src="/covoc/image/giphy.gif" alt="... loading..." />';
var searchEmpty = 'Type your search term(s) and hit ENTER to search.';

// Lauches a query to the external vocabulary server and fills in the results in the table element of the dialog searchBox

/* arguments:
 *  - start (Integer): start position of the results (for paginated results)
 * the result of the query is a JSON object with at least:
 *  - numFound (Integer): total number of results
 *  - start (Integer): the start position of the current resultset
 *  - prev (Integer - optional): the start position for the previous page, not present for first page
 *  - next (Integer - optional): the start position for the next page, not present for last page
 *  - docs (Array of JSON objects): list of results with:
 *    - uNumber (String): user identification number
 *    - fullName (String): user name in '<lastname>, <firstname>' format
 *    - affiliation (String): user's affiliation organization
 *    - eMail (String): user's email address
 *    - orcid (String - optional): user's OCRID number
 * the query server is expected to accept these query parameters:
 *  - q: the search term
 *  - from: the starting position for the results
 *  - per_page: the number of results to return per page
 */

function personQuery(start) {
  str = document.getElementById(personSearchBoxId).value;
  let table = document.querySelector('#' +  personSearchResultsId + ' tbody');
  if (!str) {
    table.innerHTML = searchEmpty;
    return;
  }
  if (!start) {
    start = 0;
  }
  // Set loading animation
  table.innerHTML = searchLoading;
  // Vocabulary search REST call
  fetch("/covoc/authors?q=" + str + '&from=' + start + '&per_page=' + page_size)
  .then(response => response.json())
  .then(data => {
    table.innerHTML = '';
    tableHeader(table, data, 'personQuery', start);
    // Iterate over results
    data.docs.forEach((doc) => {
      // id for the import button
      let id = createId();
      // Add a table row for the doc
      table.innerHTML += 
      '<tr title="' + doc.eMail + '">' +
        '<td>' + doc.fullName + '</td>' +
        '<td><a href="https://www.kuleuven.be/wieiswie/nl/person/' + doc.uNumber.slice(1) + '" target="_blank">' + doc.uNumber + '</a></td>' +
        '<td>' + 
          ((doc.orcid) ? '<a href="https://orcid.org/' + doc.orcid + '" target="_blank">' + doc.orcid + '</a>' : '') + 
        '</td>' + 
        '<td>' + 
          '<span id="' + id + '" ' + 
            'class="btn btn-default btn-xs glyphicon glyphicon-import pull-right" title="import" ' + 
            'data-covoc-fullname="' + strEncode(doc.fullName) + '" ' +
            'data-covoc-email="' + strEncode(doc.eMail) + '" ' +
            'data-covoc-affiliation="' + strEncode(doc.affiliation) + '" ' +
            'data-covoc-orcid="' + strEncode(doc.orcid) + '" ' +
            'onclick="importPersonData(\'' + id + '\');">' + 
          '</span>' + 
        '</td>' + 
      '</tr>';
    });
  });
}

// Import the query result data into the metadata form
// arguments:
// - dataID: identifier of the element that holds the covoc data attributes
function importPersonData(dataId) {
  // Get ID of target input element
  let id = document.getElementById(personSearchBoxId).getAttribute(personElementIdAttribute);
  // Get the fullName from the data element attribute
  let fullName = strDecode(document.getElementById(dataId).getAttribute('data-covoc-fullname'));
  // Get the emailAddress from the data element attribute
  let emailAddress = strDecode(document.getElementById(dataId).getAttribute('data-covoc-email'));
  // Get the affiliation from the data element attribute
  let affiliation = strDecode(document.getElementById(dataId).getAttribute('data-covoc-affiliation'));
  // Get the orcid from the data element attribute
  let orcid = strDecode(document.getElementById(dataId).getAttribute('data-covoc-orcid'));
  // Get the name input field
  let nameInput = document.getElementById(id);
  // Up to the compound element
  let compoundElement = nameInput.closest('.search_added');
  // 2nd child contains the input field for affiliation
  let affiliationInput = compoundElement.children[1].querySelector('input');
  // Fill-in name and affiliation
  nameInput.value = fullName;
  affiliationInput.value = affiliation;

  // If there are 3 children, it is a contacts field, otherwise it is an author field
  if (compoundElement.children.length > 3) {
    // Authors field
    // 3rd child is the identifier scheme wrapper and contains multiple elements:
    // - a label element that shows the current selected value
    let identifierSchemeText = compoundElement.children[2].querySelector('.ui-selectonemenu-label');
    // - a select element that contains the drop-down
    let identifierSchemeSelect = compoundElement.children[2].querySelector('select');
    // 4th child contains the input element for the identifier
    let identifierInput = compoundElement.children[3].querySelector('input');
    // Fill-in orcid identifier
    if (orcid) {
      identifierInput.value = orcid;
      // Setting the dropdown box is trickier:
      // First get the option from the select list whose text content matches the value you want to set
      let option = Array.from(identifierSchemeSelect.querySelectorAll('option')).find(el => el.text === 'ORCID');
      // Then get the value from that option and set the select element's value with it
      identifierSchemeSelect.value = option.getAttribute('value');
      // But you should also set the label field or your selection will not display
      identifierSchemeText.textContent = 'ORCID';
    } else {
      // clear the orcid input box and dropdown box
      identifierInput.value = '';
      // Default text is in the first option
      identifierSchemeText.textContent = identifierSchemeSelect.children[0].text;
      identifierSchemeSelect.value = '';
    }
  } else {
    // Contacts field
    // 3rd child is the email address
    let emailElement = compoundElement.children[2].querySelector('input');
    // Fill-in email address
    emailElement.value = emailAddress;
  }
  // Close the dialog box when the import is done
  $('#' + personModalId).modal('hide');
}

// Lauches a query to the external vocabulary server and fills in the results in the table element of the dialog searchBox

/* arguments:
 *  - start (Integer): start position of the results (for paginated results)
 * the result of the query is a JSON object with at least:
 *  - numFound (Integer): total number of results
 *  - start (Integer): the start position of the current resultset
 *  - prev (Integer - optional): the start position for the previous page, not present for first page
 *  - next (Integer - optional): the start position for the next page, not present for last page
 *  - docs (Array of JSON objects): list of results with:
 *    - id (String): publication source id (Lirias number)
 *    - doi (String): the doi of the publication, if present
 *    - issn (String): the issn of the serial, if present
 *    - url (String): publication URL
 *    - title (String): publication title
 *    - citation (String): citation text
 * the query server is expected to accept these query parameters:
 *  - q: the search term
 *  - from: the starting position for the results
 *  - per_page: the number of results to return per page
 */

function publicationQuery(start) {
  str = document.getElementById(pubSearchBoxId).value;
  let table = document.querySelector('#' +  pubSearchResultsId + ' tbody');
  if (!str) {
    table.innerHTML = searchEmpty;
    return;
  }
  if (!start) {
    start = 0;
  }
  // Set loading animation
  table.innerHTML = searchLoading;
  // Vocabulary search REST call
  fetch("/covoc/publications?q=" + str + '&from=' + start + '&per_page=' + page_size)
  .then(response => response.json())
  .then(data => {
    table.innerHTML = '';
    tableHeader(table, data, 'publicationQuery', start);
    // Iterate over results
    data.docs.forEach((doc) => {
      // id for the import button
      let id = createId();
      // Add a table row for the doc
      table.innerHTML += 
      '<tr>' +
        '<td><a href="' + doc.link + '" target="_blank">' + doc.title + '</a></td>' +
        '<td>' + 
          '<span id="' + id + '" ' + 
            'class="btn btn-default btn-xs glyphicon glyphicon-import pull-right" title="import" ' + 
            'data-covoc-citation="' + strEncode(doc.citation) + '" ' +
            'data-covoc-id="' + strEncode(doc.id) + '" ' +
            'data-covoc-doi="' + strEncode(doc.doi) + '" ' +
            'data-covoc-issn="' + strEncode(doc.issn) + '" ' +
            'data-covoc-url="' + strEncode(doc.url) + '" ' +
            'onclick="importPublicationData(\'' + id + '\');">' + 
          '</span>' + 
        '</td>' + 
      '</tr>';
    });
  });
}

// Import the query result data into the metadata form
// arguments:
// - dataID: identifier of the element that holds the covoc data attributes
function importPublicationData(dataId) {
  // Get ID of target input element
  let id = document.getElementById(pubSearchBoxId).getAttribute(pubElementIdAttribute);
  // Get the citation from the data element attribute
  let citation = strDecode(document.getElementById(dataId).getAttribute('data-covoc-citation'));
  // Get the sourceId from the data element attribute
  let sourceId = strDecode(document.getElementById(dataId).getAttribute('data-covoc-id'));
  // Get the doi from the data element attribute
  let doi = strDecode(document.getElementById(dataId).getAttribute('data-covoc-doi'));
  // Get the issn from the data element attribute
  let issn = strDecode(document.getElementById(dataId).getAttribute('data-covoc-issn'));
  // Get the url from the data element attribute
  let url = strDecode(document.getElementById(dataId).getAttribute('data-covoc-url'));
  // Get the search input field
  let idInput = document.getElementById(id);
  // Up to the compound element
  let compoundElement = idInput.closest('.search_added');
  // 1st child contains the citation
  let citationInput = compoundElement.children[0].querySelector('textarea');
  // 5th child contains the URL
  let urlInput = compoundElement.children[4].querySelector('input');
  // Fill-in name and affiliation
  idInput.value = sourceId;
  urlInput.value = url;

  // 2nd child is the identifier scheme wrapper and contains multiple elements:
  // - a label element that shows the current selected value
  let identifierSchemeText = compoundElement.children[1].querySelector('.ui-selectonemenu-label');
  // - a select element that contains the drop-down
  let identifierSchemeSelect = compoundElement.children[1].querySelector('select');
  // 3rd child contains the input element for the identifier
  let identifierInput = compoundElement.children[2].querySelector('input');
  // Fill-in doi
  if (doi) {
    identifierInput.value = doi;
    // Setting the dropdown box is trickier:
    // First get the option from the select list whose text content matches the value you want to set
    let option = Array.from(identifierSchemeSelect.querySelectorAll('option')).find(el => el.text === 'doi');
    // Then get the value from that option and set the select element's value with it
    identifierSchemeSelect.value = option.getAttribute('value');
    // But you should also set the label field or your selection will not display
    identifierSchemeText.textContent = 'doi';
  } else if(issn) {
    identifierInput.value = issn;
    // Setting the dropdown box is trickier:
    // First get the option from the select list whose text content matches the value you want to set
    let option = Array.from(identifierSchemeSelect.querySelectorAll('option')).find(el => el.text === 'issn');
    // Then get the value from that option and set the select element's value with it
    identifierSchemeSelect.value = option.getAttribute('value');
    // But you should also set the label field or your selection will not display
    identifierSchemeText.textContent = 'issn';
  } else {
    // clear the orcid input box and dropdown box
    identifierInput.value = '';
    // Default text is in the first option
    identifierSchemeText.textContent = identifierSchemeSelect.children[0].text;
    identifierSchemeSelect.value = '';
  }

  // Get the citation data from reporting database
  fetch('/covoc/citation?id=' + sourceId)
  .then(response => response.json())
  .then(data => {
    if (data.status == 200) {
      // Fill in the citation
      citationInput.value = data.citation;
    } else {
      // No citation found
      citationInput.value = '';
      message = 'Citation service ';
      if (data.status == 404) {
        alert('Citation service could not find the publication.\n\nPlease copy and paste the citation yourself.');
      } else if (data.status = 503) {
        alert('Citation service temporarily unavailable.\n\nPlease try again later.');
      } else {
        alert('Citation service returned an error ' + 
          (data.error ? ': ' + data.error : ' status: ' + data.status) +
          '.\n\nPlease copy and paste the citation yourself.'
        );
      }
    }
  });
  // Close the dialog box when the import is done
  $('#' + pubModalId).modal('hide');
}
