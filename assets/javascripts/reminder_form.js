$(document).ready(function() {
  var isRecurringCheckbox = $('.is-recurring-checkbox');
  var recurringOptions = $('#recurring-options');
  var recurringTypeSelect = $('#recurring_type_select');
  var customDaysOptions = $('#custom-days-options');
  var hiddenCustomDays = $('#hidden_custom_days');
  var customDayCheckboxes = $('.custom-day-checkbox');

  function toggleRecurringOptions() {
    if (isRecurringCheckbox.is(':checked')) {
      recurringOptions.show();
    } else {
      recurringOptions.hide();
    }
  }

  function toggleCustomDaysOptions() {
    if (recurringTypeSelect.val() === 'custom') {
      customDaysOptions.show();
    } else {
      customDaysOptions.hide();
    }
  }

  function updateHiddenCustomDays() {
    var selectedDays = customDayCheckboxes.filter(':checked').map(function() {
      return $(this).val();
    }).get().join(',');
    hiddenCustomDays.val(selectedDays);
  }

  if (isRecurringCheckbox.length) {
    isRecurringCheckbox.on('change', toggleRecurringOptions);
  }

  if (recurringTypeSelect.length) {
    recurringTypeSelect.on('change', toggleCustomDaysOptions);
  }

  if (customDayCheckboxes.length) {
    customDayCheckboxes.on('change', updateHiddenCustomDays);
  }

  // Initial setup
  toggleRecurringOptions();
  toggleCustomDaysOptions();
  updateHiddenCustomDays();

  // Debug form submit
  $('form').on('submit', function() {
    console.log('Form submitting. Issue ID field value:', issueIdField.val());
    console.log('All form data:', $(this).serialize());
  });

  // Initialize custom issue search
  var issueSearchInput = $('#issue-search-input');
  var issueSearchResults = $('#issue-search-results');
  var issueIdField = $('input[name="reminder[issue_id]"]');
  var clearIssueLink = $('.clear-issue');
  var currentIssueDiv = $('.current-issue');
  var searchTimeout;

  console.log('Issue ID field found:', issueIdField.length); // Debug log
  console.log('Issue ID field attr name:', issueIdField.attr('name')); // Debug log
  console.log('Issue ID field current value:', issueIdField.val()); // Debug log
  
  // Debug: find all inputs to see what IDs Rails actually created
  console.log('All hidden inputs in form:');
  $('form input[type="hidden"]').each(function() {
    console.log('Hidden input - ID:', $(this).attr('id'), 'Name:', $(this).attr('name'), 'Value:', $(this).val());
  });

  if (issueSearchInput.length) {
    // Handle input typing
    issueSearchInput.on('input', function() {
      var query = $(this).val();
      
      clearTimeout(searchTimeout);
      
      if (query.length >= 0) {
        searchTimeout = setTimeout(function() {
          searchIssues(query);
        }, 300);
      } else {
        issueSearchResults.hide();
      }
    });

    // Handle focus to show recent issues
    issueSearchInput.on('focus', function() {
      if ($(this).val() === '') {
        searchIssues('');
      }
    });

    // Handle click outside to hide results
    $(document).on('click', function(e) {
      if (!$(e.target).closest('.issue-search-container').length) {
        issueSearchResults.hide();
      }
    });

    // Handle clear issue
    clearIssueLink.on('click', function(e) {
      e.preventDefault();
      issueIdField.val('');
      issueSearchInput.val('');
      currentIssueDiv.hide();
    });

    function searchIssues(query) {
      var searchUrl = issueSearchInput.data('search-url');
      
      $.ajax({
        url: searchUrl,
        type: 'GET',
        dataType: 'json',
        data: { q: query },
        success: function(data) {
          displaySearchResults(data.results);
        },
        error: function() {
          issueSearchResults.hide();
        }
      });
    }

    function displaySearchResults(results) {
      if (results.length === 0) {
        issueSearchResults.hide();
        return;
      }

      var html = '<ul class="issue-search-list" style="list-style: none; padding: 0; margin: 0; border: 1px solid #ccc; background: white; max-height: 200px; overflow-y: auto; position: absolute; width: 250px; box-shadow: 0 2px 5px rgba(0,0,0,0.2);">';
      
      results.forEach(function(issue) {
        html += '<li class="issue-search-item" data-id="' + issue.id + '" data-text="' + issue.text + '" style="padding: 8px 12px; cursor: pointer; border-bottom: 1px solid #eee; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">' + issue.text + '</li>';
      });
      
      html += '</ul>';
      
      issueSearchResults.html(html).show();

      // Handle result selection
      $('.issue-search-item').on('click', function() {
        var issueId = $(this).data('id');
        var issueText = $(this).data('text');
        
        console.log('Selected issue ID:', issueId); // Debug log
        console.log('Hidden field before:', issueIdField.val()); // Debug log
        
        issueIdField.val(issueId);
        issueSearchInput.val(issueText);
        issueSearchResults.hide();
        
        console.log('Hidden field after:', issueIdField.val()); // Debug log
        
        // Update current issue display
        currentIssueDiv.html('<strong>Selected Issue:</strong> ' + issueText + ' <a href="#" class="clear-issue" style="margin-left: 10px; color: #d00;">[Clear]</a>').show();
        
        // Re-bind clear event
        $('.clear-issue').on('click', function(e) {
          e.preventDefault();
          console.log('Clearing issue selection'); // Debug log
          issueIdField.val('');
          issueSearchInput.val('');
          currentIssueDiv.hide();
        });
      });

      // Handle hover effects
      $('.issue-search-item').on('mouseenter', function() {
        $(this).css('background-color', '#f0f0f0');
      }).on('mouseleave', function() {
        $(this).css('background-color', 'white');
      });
    }
  }
}); 
