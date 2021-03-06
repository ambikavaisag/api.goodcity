module Api::V1
  class OrganisationNamesSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :name_en, :name_zh_tw
  end
end
