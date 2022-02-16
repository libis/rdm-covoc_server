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
var personSearchResultsID = 'person-search-results';
var personElementIdAttribute = 'data-person-element-id';
var personSearchIconText = 'Search in KU Leuven';

// Selector for all the author compound fields
var authorSelector = "#metadata_author ~ .dataset-field-values .edit-compound-field";

// Selector for all the contact compound fields
var contactSelector = "#metadata_datasetContact ~ .dataset-field-values .edit-compound-field";

/* The browser will run this code the first time the editor is opened and each time a multiple field instance is 
 * added or removed. This code is reposible for creating the HTML for the dialog box, adding a search button to 
 * the name fields and creating the triggers for initializing the dialog box and the search action itself.
 */
$(document).ready(function() {

  // Create modal
  createModal(personModalId, personModalTitle, personModalPlaceholder, personModalHelptext, 
    personSearchBoxId, personSearchResultsID, personElementIdAttribute, personQuery);

  // Put a search button after each name field
  putNameSearchIcon(authorSelector, personElementIdAttribute, personModalId, personSearchIconText);

  // Put a search button after each contact name field
  putNameSearchIcon(contactSelector, personElementIdAttribute, personModalId, personSearchIconText);
});

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
      // Fill in the input field text in the searchBox ...
      let searchBox = document.getElementById(searchBoxId);
      searchBox.value = nameElement.value;
      // ... and launch a query
      queryFunction(nameElement.value, 0);
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
        // Get string from searchBox ...
        let str = this.value;
        // ... and launch query ...
        queryFunction(this.value, 0);
        // .. and prevent key to be added to the searchBox
        e.preventDefault();
      }
    });
  }
}

// Generic function that add a search button to the name input fields
function putNameSearchIcon(selector, elementIdAttribute, modalId, searchIconText) {
  // Iterate over compund elements
  document.querySelectorAll(selector).forEach(element => {
    // 'search_added' class marks elements that have already been processed
    if (!element.classList.contains('search_added')) {
      element.classList.add('search_added');
      // First child is element that encapsulates label and input of name
      let nameField = element.children[0];
      // Input field within
      let nameInput = nameField.querySelector('input');
      // We create an bootstrap input group ...
      let wrapper = document.createElement('div');
      wrapper.className = 'input-group';
      wrapper.style.display = 'flex';
      // ... containing the input field ...
      wrapper.appendChild(nameInput);
      // ... and a new seach button ...
      let searchButton = document.createElement('button');
      element.setAttribute('aria-describedby', searchButton.id);
      searchButton.className = 'btn btn-default btn-sm bootstrap-button-tooltip compound-field-btn';
      searchButton.setAttribute('type', 'button');
      searchButton.setAttribute('title', searchIconText);
      searchButton.setAttribute('data-toggle', 'modal');
      searchButton.setAttribute('data-target', '#' + modalId);
      searchButton.setAttribute(elementIdAttribute, nameInput.id);
      let searchIcon = document.createElement('span');
      searchIcon.className = 'glyphicon glyphicon-search no-text';
      searchButton.appendChild(searchIcon);
      wrapper.appendChild(searchButton);
      // ... and add that to the encapsulating element.
      nameField.appendChild(wrapper);
    }
  })
}

// Import the query result data into the metadata form
// arguments:
// - id (String): identifier of the name input field
// - fullName, emailAddress, affiliation and orcid (String): person data
function importPersonData(id, fullName, emailAddress, affiliation, orcid) {
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

var page_size = 10; // Number of results that will be displayed on a single page

// Lauches a query to the external vocabulary server and fills in the results in the table element of the dialog searchBox

/* arguments:
 *  - str (String): text to search for
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

function personQuery(str, start) {
  if (!start) {
    start = 0;
  }
  // Vocabulary search REST call
  fetch("/covoc/authors?q=" + str + '&from=' + start + '&per_page=' + page_size)
  .then(response => response.json())
  .then(data => {
    let table = document.querySelector('#' +  personSearchResultsID + ' tbody');
    // Clear table content
    table.innerHTML = ''
    // Add pagination header
    if (data.hasOwnProperty('prev') || data.hasOwnProperty('next')) {
      table.innerHTML += 
      '<tr>' + 
        '<td class="row" colspan="4">' +
          '<div class="col-sm-2">' +
            ((data.hasOwnProperty('prev'))
              ? '<span class="btn btn-default btn-xs pull-left" accesskey="p" onclick="personQuery(\'' + str + '\', ' + data.prev + ')">&lt;&lt;</span>'
              : ''
            ) +
          '</div>' +
          '<div class="col-sm-8 text-center">' +
            (start + 1) + '-' + (start + data.docs.length) + ' of ' + data.numFound +
          '</div>' +
          '<div class="col-sm-2">' +
            ((data.hasOwnProperty('next'))
              ? '<span class="btn btn-default btn-xs pull-right" accesskey="n" onclick="personQuery(\'' + str + '\', ' + data.next + ')">&gt;&gt;</span>'
              : ''
            ) +
          '</div>' +
        '</td>' +
      '</tr>';
    }
    // Iterate over results
    data.docs.forEach((doc) => {
      // Get ID of target input element
      let id = document.getElementById(personSearchBoxId).getAttribute(personElementIdAttribute);
      // Add a table row for the doc
      table.innerHTML += 
      '<tr title="' + doc.eMail + '">' +
        '<td>' + doc.fullName + '</td>' +
        '<td><a href="https://www.kuleuven.be/wieiswie/nl/person/' + doc.uNumber.slice(1) + '" target="_blank">' + doc.uNumber + '</a></td>' +
        '<td>' + 
          ((doc.orcid) ? '<a href="https://orcid.org/' + doc.orcid + '" target="_blank">' + doc.orcid + '</a>' : '') + 
        '</td>' + 
        '<td>' + 
          '<span ' + 
            'class="btn btn-default btn-xs glyphicon glyphicon-import pull-right" title="import" ' + 
            'onclick="importPersonData(\'' + id + '\', \'' + doc.fullName + '\', \'' + doc.eMail + '\', \'' + doc.affiliation + '\', \'' + (doc.orcid || '') + '\');">' + 
          '</span>' + 
        '</td>' + 
      '</tr>';
    });
  });
}
