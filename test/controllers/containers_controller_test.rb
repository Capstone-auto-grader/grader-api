require 'test_helper'

class ContainersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @container = containers(:one)
  end

  test "should get index" do
    get containers_url, as: :json
    assert_response :success
  end

  test "should create container" do
    assert_difference('Container.count') do
      post containers_url, params: { container: { config_uri: @container.config_uri, name: @container.name, uid: @container.uid } }, as: :json
    end

    assert_response 201
  end

  test "should show container" do
    get container_url(@container), as: :json
    assert_response :success
  end

  test "should update container" do
    patch container_url(@container), params: { container: { config_uri: @container.config_uri, name: @container.name, uid: @container.uid } }, as: :json
    assert_response 200
  end

  test "should destroy container" do
    assert_difference('Container.count', -1) do
      delete container_url(@container), as: :json
    end

    assert_response 204
  end
end
