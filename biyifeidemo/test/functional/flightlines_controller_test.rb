require 'test_helper'

class FlightlinesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:flightlines)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create flightline" do
    assert_difference('Flightline.count') do
      post :create, :flightline => { }
    end

    assert_redirected_to flightline_path(assigns(:flightline))
  end

  test "should show flightline" do
    get :show, :id => flightlines(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => flightlines(:one).to_param
    assert_response :success
  end

  test "should update flightline" do
    put :update, :id => flightlines(:one).to_param, :flightline => { }
    assert_redirected_to flightline_path(assigns(:flightline))
  end

  test "should destroy flightline" do
    assert_difference('Flightline.count', -1) do
      delete :destroy, :id => flightlines(:one).to_param
    end

    assert_redirected_to flightlines_path
  end
end
