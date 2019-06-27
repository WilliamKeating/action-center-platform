require "rails_helper"

RSpec.describe "Congress Messages", type: :request do
  let!(:members) {
    [FactoryGirl.create(:congress_member, state: "CA", bioguide_id: "C000880"),
     FactoryGirl.create(:congress_member, state: "CA", bioguide_id: "A000360")]
  }

  let(:action_page) {
    FactoryGirl.create(:action_page_with_congress_message)
  }

  let(:location) {
    OpenStruct.new(success: true,
                   street: "1630 Ravello Drive",
                   city: "Sunnydale",
                   zipcode: 94109,
                   zip4: 1234,
                   state: "CA",
                   district: 10)
  }

  before do
    allow(SmartyStreets).to receive(:get_location).and_return(location)

    stub_request(:post, /retrieve-form-elements/).
      with(body: { "bio_ids" => ["C000880", "A000360"] }).
      and_return(status: 200, body: file_fixture("retrieve-form-elements.json"))
  end

  describe "new" do
    subject {
      get("/congress_messages/new", params: {
          congress_message_campaign_id: action_page.congress_message_campaign_id,
          street_address: location.street,
          zipcode: location.zipcode
        })
    }

    it "renders the congress message form" do
      subject
      expect(response.body).to include '<input type="text" name="$NAME_FIRST" id="_NAME_FIRST" class="form-control" placeholder="Your first name" aria-label="Your first name" required="required" />'
      # Select from array
      expect(response.body).to include '<option value="Animal_Rights">Animal_Rights</option>'
      # Select from hash
      expect(response.body).to include '<option value="AK">ALASKA</option>'
    end

    it "renders address fields as hidden" do
      subject
      expect(response.body).to include '<input type="hidden" name="$ADDRESS_STREET"'
    end

    it "displays an error when address lookup fails" do
      pending("error handling")
      allow(SmartyStreets).to receive(:get_location)
        .and_return(OpenStruct.new(success: false))
      subject
      expect(response.body).to include "address lookup failed"
    end

    it "displays an error when congress member lookup fails" do
      pending("error handling")
      location.state = "OR"
      allow(SmartyStreets).to receive(:get_location).and_return(location)
      subject
      expect(response.body).to include "couldn't find any members"
    end
  end
end