require "rails_helper"

RSpec.describe AgoraCallbacksController, type: :controller do
  let(:agora_new_mp4_record_event_body) {
    # keep it compact to avoid formatting issues
    {"eventType":101,"noticeId":"1111-1111-1111-1111","notifyMs":1560408533119,"productId":7,"payload":{"eventName":"new_standard_record_file","entryPoint":"live","streamName":"TEST1","fileName":"record/live/test_stream/video.mp4"}}
  }
  let(:agora_new_mp4_record_event_signature) { "d6954af61ffcfe9954b61484967b73e760eeb3627fdf591bf11557b86940278a" }

  let(:agora_new_hls_record_event_body) {
    # keep it compact to avoid formatting issues
    {"eventType":101,"noticeId":"1111-1111-1111-1111","notifyMs":1560408533119,"productId":7,"payload":{"eventName":"new_standard_record_file","entryPoint":"live","streamName":"TEST1","fileName":"record/live/test_stream/video.m3u8"}}
  }
  let(:agora_new_hls_record_event_signature) { "ca8c0b0d5afdc24a2e0eaa0e0efb55e6c7089111e981f7fb7b786a31e958b7bb" }

  describe "POST index" do
    describe "with an invalid signature" do
      it "returns a 400" do
        request.headers['Agora-Signature-V2'] = "invalid-signature"
        post :index, params: agora_new_mp4_record_event_body, as: :json
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "with a valid signature" do
      let(:live_room) { create(:live_room, id: 1) }
      it "save mp4 filenames" do
        expect(live_room.agora_mp4_filenames).to be_empty

        request.headers['Content-Type'] = 'application/json'
        request.headers['Agora-Signature-V2'] = agora_new_mp4_record_event_signature

        post :index, params: agora_new_mp4_record_event_body, as: :json

        expect(response).to have_http_status(:ok)

        live_room.reload
        expect(live_room.agora_mp4_filenames).to include(agora_new_mp4_record_event_body[:payload][:fileName])
      end

      it "save hls filename" do
        expect(live_room.agora_vod_filename).to be_nil

        request.headers['Content-Type'] = 'application/json'
        request.headers['Agora-Signature-V2'] = agora_new_hls_record_event_signature

        post :index, params: agora_new_hls_record_event_body, as: :json

        expect(response).to have_http_status(:ok)

        live_room.reload
        expect(live_room.agora_vod_filename).to eq(agora_new_hls_record_event_body[:payload][:fileName])
      end
    end
  end
end
