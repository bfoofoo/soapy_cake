# frozen_string_literal: true

module SoapyCake
  # rubocop:disable Metrics/ClassLength
  class Admin < Client
    include Helper

    def affiliate_bills(opts = {})
      run Request.new(:admin, :accounting, :export_affiliate_bills, opts)
    end

    def advertiser_bills(opts = {})
      run Request.new(:admin, :accounting, :export_advertiser_bills, opts)
    end

    def mark_affiliate_bill_as_received(opts = {})
      run Request.new(:admin, :accounting, :mark_affiliate_bill_as_received, opts)
    end

    def mark_affiliate_bill_as_paid(opts = {})
      run Request.new(:admin, :accounting, :mark_affiliate_bill_as_paid, opts)
    end

    def advertisers(opts = {})
      run Request.new(:admin, :export, :advertisers, opts)
    end

    def affiliates(opts = {})
      run Request.new(:admin, :export, :affiliates, opts)
    end

    def affiliate_referrals(opts = {})
      run Request.new(:admin, :export, :affiliate_referrals, opts)
    end

    def campaigns(opts = {})
      run Request.new(:admin, :export, :campaigns, opts)
    end

    def offers(opts = {})
      run Request.new(:admin, :export, :offers, opts)
    end

    def creatives(opts = {})
      opts = translate_values(opts)

      run Request.new(:admin, :export, :creatives, opts)
    end

    def buyers(opts = {})
      run Request.new(:admin, :export, :buyers, opts)
    end

    def buyer_contracts
      run Request.new(:admin, :export, :buyer_contracts, opts)
    end

    def schedules(opts = {})
      run Request.new(:admin, :export, :schedules, opts)
    end

    def campaign_summary(opts = {})
      run Request.new(:admin, :reports, :campaign_summary, opts)
    end

    def offer_summary(opts = {})
      run Request.new(:admin, :reports, :offer_summary, opts)
    end

    def affiliate_summary(opts = {})
      run Request.new(:admin, :reports, :affiliate_summary, opts)
    end

    def advertiser_summary(opts = {})
      run Request.new(:admin, :reports, :advertiser_summary, opts)
    end

    def clicks(opts = {})
      run Request.new(:admin, :reports, :clicks, opts)
    end

    def conversion_changes(opts = {})
      run Request.new(:admin, :reports, :conversion_changes, opts)
    end

    def conversions(opts = {})
      run event_conversions_request('macro_event_conversions', opts)
    end

    def events(opts = {})
      run event_conversions_request('micro_events', opts)
    end

    def traffic(opts = {})
      run Request.new(:admin, :reports, :traffic_export, opts)
    end

    def caps(opts)
      require_params(opts, %i[start_date end_date])
      opts = translate_values(opts)

      run Request.new(:admin, :reports, :caps, opts)
    end

    def exchange_rates(opts)
      require_params(opts, %i[start_date end_date])

      run Request.new(:admin, :get, :exchange_rates, opts)
    end

    def currencies
      run Request.new(:admin, :get, :currencies, {})
    end

    def tiers
      run Request.new(:admin, :get, :affiliate_tiers, {})
    end

    def update_creative(opts = {})
      run Request.new(:admin, :addedit, :creative, opts)
    end

    def update_campaign(opts = {})
      run Request.new(:admin, :addedit, :campaign, opts)
    end

    def add_blacklist(opts)
      require_params(opts, %i[blacklist_date])

      blacklist_date = opts[:blacklist_date].to_date
      # CAKE applies the blacklisting at 00:00 of the specified day, so add one more day.
      # Unless it is the current day, then blacklisting should take effect immediately.
      blacklist_date += 1.day if blacklist_date > Date.current

      run Request.new(
        :admin,
        :addedit,
        :blacklist,
        opts.merge(blacklist_date: blacklist_date)
      )
    end

    def blacklists(opts = {})
      run Request.new(:admin, :export, :blacklists, opts)
    end

    def remove_blacklist(opts = {})
      require_params(opts, %i[blacklist_id])
      run Request.new(:admin, :addedit, :remove_blacklist, opts)
    end

    def affiliate_signup(opts = {})
      run Request.new(:admin, :signup, :affiliate, opts)
    end

    def media_types(opts = {})
      result = run(Request.new(:admin, :signup, :get_media_types, opts))
      xml_response? ? result : result.try(:[], :MediaType)
    end

    def verticals
      run Request.new(:admin, :get, :verticals, {})
    end

    def countries(opts = {})
      run Request.new(:admin, :get, :countries, opts)
    end

    def payment_types
      run Request.new(:admin, :get, :payment_types, {})
    end

    def blacklist_reasons
      run Request.new(:admin, :get, :blacklist_reasons, {})
    end

    private

    def event_conversions_request(event_type, opts)
      Request.new(:admin, :reports, :event_conversions, opts.merge(event_type: event_type))
    end
  end
  # rubocop:enable Metrics/ClassLength
end
