require 'test_helper'

class SegmentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:segments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create segment" do
    assert_difference('Segment.count') do
      post :create, :segment => { }
    end

    assert_redirected_to segment_path(assigns(:segment))
  end

  test "should show segment" do
    get :show, :id => segments(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => segments(:one).to_param
    assert_response :success
  end

  test "should update segment" do
    put :update, :id => segments(:one).to_param, :segment => { }
    assert_redirected_to segment_path(assigns(:segment))
  end

  test "should destroy segment" do
    assert_difference('Segment.count', -1) do
      delete :destroy, :id => segments(:one).to_param
    end

    assert_redirected_to segments_path
  end
end
