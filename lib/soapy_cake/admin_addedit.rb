# frozen_string_literal: true

module SoapyCake
  # rubocop:disable Metrics/ClassLength
  class AdminAddedit < Client
    include Helper

    OFFER_DEFAULT_OPTIONS = {
      offer_name: '',
      third_party_name: '',
      hidden: 'no_change',
      offer_status_id: 0,
      ssl: 'no_change',
      click_cookie_days: -1,
      impression_cookie_days: -1,
      redirect_offer_contract_id: 0,
      redirect_404: 'no_change',
      enable_view_thru_conversions: 'no_change',
      click_trumps_impression: 'no_change',
      disable_click_deduplication: 'no_change',
      last_touch: 'no_change',
      enable_transaction_id_deduplication: 'no_change',
      postbacks_only: 'no_change',
      pixel_html: '',
      postback_url: '',
      fire_global_pixel: 'no_change',
      fire_pixel_on_non_paid_conversions: 'no_change',
      expiration_date_modification_type: 'do_not_change',
      offer_contract_name: '',
      offer_link: '',
      thankyou_link: '',
      preview_link: '',
      thumbnail_file_import_url: '',
      offer_description: '',
      restrictions: '',
      advertiser_extended_terms: '',
      testing_instructions: '',
      allow_affiliates_to_create_creatives: 'no_change',
      unsubscribe_link: '',
      from_lines: '',
      subject_lines: '',
      conversions_from_whitelist_only: 'off',
      allowed_media_type_modification_type: 'do_not_change',
      track_search_terms_from_non_supported_search_engines: 'off',
      auto_disposition_type: 'none',
      auto_disposition_delay_hours: '0',
      session_regeneration_seconds: -1,
      session_regeneration_type_id: 0,
      payout_modification_type: 'change',
      received_modification_type: 'change',
      tags_modification_type: 'do_not_change'
    }.freeze

    REQUIRED_NEW_OFFER_PARAMS = %i[
      hidden offer_status_id offer_type_id currency_id ssl click_cookie_days
      impression_cookie_days redirect_404 enable_view_thru_conversions
      click_trumps_impression disable_click_deduplication last_touch
      enable_transaction_id_deduplication postbacks_only fire_global_pixel
      fire_pixel_on_non_paid_conversions offer_link thankyou_link from_lines
      subject_lines
    ].freeze

    REQUIRED_OFFER_PARAMS = %i[
      advertiser_id vertical_id postback_url_ms_delay offer_contract_hidden
      price_format_id received received_percentage payout tags
    ].freeze

    REQUIRED_OFFER_CONTRACT_PARAMS = %i[
      offer_id offer_contract_id offer_contract_name price_format_id payout received
      received_percentage offer_link thankyou_link offer_contract_hidden
      offer_contract_is_default use_fallback_targeting
    ].freeze

    def add_offer(opts)
      require_params(opts, REQUIRED_NEW_OFFER_PARAMS)

      addedit_offer(opts.merge(offer_id: 0))
    end

    def edit_offer(opts = {})
      validate_id(opts, :offer_id)

      addedit_offer(opts)
    end

    def edit_contact(opts)
      require_params(opts, %i[entity_id contact_id contact_email_address])

      run Request.new(:admin, :addedit, :contact, opts)
    end

    def add_geo_targets(opts)
      edit_geo_targets(opts.merge(add_edit_option: 'add'))
    end

    def edit_geo_targets(opts)
      require_params(opts, %i[offer_contract_id allow_countries])

      opts = if opts[:allow_countries]
               geo_targets_allow_options(opts)
             else
               geo_targets_redirect_options(opts)
             end

      opts[:add_edit_option] ||= 'replace'
      opts[:set_targeting_to_geo] = true

      run Request.new(:admin, :addedit, :geo_targets, opts)
    end

    def geo_targets_allow_options(opts)
      require_params(opts, %i[countries])
      opts = opts.dup
      countries = Array(opts[:countries])
      opts[:countries] = countries.join(',')
      opts[:redirect_site_offer_contract_ids] = ([-1] * countries.count).join(',')
      opts
    end

    def geo_targets_redirect_options(opts)
      opts = opts.dup
      redirects = opts.delete(:redirects)
      unless redirects.is_a?(Hash) && redirects.keys.count.positive?
        raise Error, "Parameter 'redirects' must be a COUNTRY=>REDIRECT_OFFER_CONTRACT_ID hash!"
      end

      opts[:countries] = redirects.keys.join(',')
      opts[:redirect_site_offer_contract_ids] = redirects.values.join(',')
      opts
    end

    def add_offer_contract(opts = {})
      addedit_offer_contract(opts.merge(offer_contract_id: 0))
    end

    def edit_offer_contract(opts = {})
      validate_id(opts, :offer_contract_id)

      addedit_offer_contract(opts)
    end

    def update_caps(opts)
      require_params(opts, %i[cap_type_id cap_interval_id cap_amount send_alert_only])

      opts = translate_values(opts)

      run Request.new(:admin, :addedit, :caps, opts)
    end

    def remove_caps(opts)
      require_params(opts, %i[cap_type_id])

      opts = translate_values(opts)

      opts = opts.merge(cap_interval_id: 0, cap_amount: -1, send_alert_only: false)
      run Request.new(:admin, :addedit, :caps, opts)
    end

    def add_offer_tier(opts)
      addedit_offer_tier('add', opts)
    end

    def edit_offer_tier(opts)
      addedit_offer_tier('replace', opts)
    end

    def edit_affiliate(opts)
      require_params(opts, %i[affiliate_id vat_tax_required])

      run Request.new(:admin, :addedit, :affiliate, opts)
    end

    def create_advertiser(opts)
      run Request.new(:admin, :addedit, :advertiser, opts.merge(advertiser_id: 0))
    end

    ALLOWED_CREATIVE_OPTS = %i[
      creative_name
      creative_status_id
      creative_type_id
      height
      notes
      offer_id
      offer_link
      third_party_name
      width
    ].freeze

    ALLOWED_CREATIVE_FILES_OPTS = %i[
      creative_file_id
      creative_file_import_url
      creative_id
      is_preview_file
      replace_all_files
    ].freeze

    def create_creative(opts)
      raise 'need offer_id to create creative' if opts[:offer_id].blank?
      raise 'cannot pass creative_id when creating creative' if opts[:creative_id].present?

      creative_opts = opts.select { |key, _| ALLOWED_CREATIVE_OPTS.include? key }
      create_result = addedit_creative(creative_opts)

      files_opts = opts.select { |key, _| ALLOWED_CREATIVE_FILES_OPTS.include? key }
        .merge(creative_id: create_result[:creative_id])

      create_result.merge(addedit_creative_files(files_opts)).except(:message)
    end

    private

    def addedit_creative(opts)
      defaults = {
        creative_name: '',
        creative_status_id: 1, # Active: 1, Inactive: 2, Hidden: 3
        creative_type_id: 3, # Link: 1, Image: 3, Flash: 4, HTML: 6, Email: 2, Text: 5, Video: 7
        height: 0,
        notes: '',
        offer_link: '',
        third_party_name: '',
        width: 0
      }

      run Request.new(:admin, :addedit, :creative, defaults.merge(opts))
    end

    def addedit_creative_files(opts)
      run Request.new(:admin, :addedit, :creative_files, opts)
    end

    def addedit_offer_tier(add_edit_option, opts)
      require_params(opts, %i[offer_id tier_id price_format_id offer_contract_id status_id])

      opts = opts.merge(redirect_offer_contract_id: -1, add_edit_option: add_edit_option)
      opts = translate_values(opts)

      run Request.new(:admin, :addedit, :offer_tiers, opts)
    end

    def apply_tag_opts(opts)
      return opts unless opts[:tags]
      opts = apply_tag_modification_type(opts)
      opts[:tags] = Array(opts[:tags]).join(',')
      opts
    end

    def apply_tag_modification_type(opts)
      opts = opts.dup
      opts[:tags_modification_type] =
        if opts[:tags].to_s == ''
          'remove_all'
        elsif opts.delete(:tags_replace) && opts[:offer_id].nonzero?
          'replace'
        else
          'add'
        end
      opts
    end

    def default_offer_options
      OFFER_DEFAULT_OPTIONS.merge(
        conversion_cap_behavior: const_lookup(:conversion_behavior_id, :system),
        conversion_behavior_on_redirect: const_lookup(:conversion_behavior_id, :system),
        expiration_date: future_expiration_date
      )
    end

    def addedit_offer(opts)
      require_params(opts, REQUIRED_OFFER_PARAMS)

      opts = translate_booleans(opts)
      opts = apply_tag_opts(opts)
      opts = translate_values(opts)

      run(Request.new(:admin, :addedit, :offer, default_offer_options.merge(opts)))[:success_info]
    end

    def addedit_offer_contract(opts)
      require_params(opts, REQUIRED_OFFER_CONTRACT_PARAMS)
      opts = translate_values(opts)

      run Request.new(:admin, :addedit, :offer_contract, opts)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
