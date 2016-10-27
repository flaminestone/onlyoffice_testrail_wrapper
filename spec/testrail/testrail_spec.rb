require 'spec_helper'

describe OnlyofficeTestrailWrapper::Testrail2 do
  describe 'Tesrail Run' do
    it 'TestrailProject.plan' do
      project = OnlyofficeTestrailWrapper::Testrail2.new.project('Canvas Document Editor Autotests')
      expect(project.plan('ver. 3.5.0 (build:199, rev:65637)')).to be_a(OnlyofficeTestrailWrapper::TestrailPlan)
    end

    it 'TestrailProject.runs' do
      project = OnlyofficeTestrailWrapper::Testrail2.new.project('Canvas Document Editor Autotests')
      expect(project.plan('ver. 3.5.0 (build:199, rev:65637)').runs).to be_a(Array)
      expect(project.plan('ver. 3.5.0 (build:199, rev:65637)').runs.first).to be_a(OnlyofficeTestrailWrapper::TestrailRun)
    end

    it 'TestrailProject.plan.run' do
      project = OnlyofficeTestrailWrapper::Testrail2.new.project('Canvas Document Editor Autotests')
      expect(project.plan('ver. 3.5.0 (build:199, rev:65637)').run('All Formulas')).to be_a(OnlyofficeTestrailWrapper::TestrailRun)
    end

    it 'TestrailProject.plan.run unknown name' do
      project = OnlyofficeTestrailWrapper::Testrail2.new.project('Canvas Document Editor Autotests')
      expect(project.plan('ver. 3.5.0 (build:199, rev:65637)').run('non-existing')).to be_nil
    end

    it 'TestrailProject.plan.run.duration' do
      project = OnlyofficeTestrailWrapper::Testrail2.new.project('Canvas Document Editor Autotests')
      run = project.plan('ver. 3.5.0 (build:199, rev:65637)').run('[Version history] for Table Smoke Test')
      expect(run.duration).to be > 0.1
    end
  end

  describe 'TestrailProject' do
    it 'TestrailProject#get_plans with filter' do
      project = OnlyofficeTestrailWrapper::Testrail2.new.project('Canvas Document Editor Autotests')
      plans_without_filter = project.get_plans
      plans_filtered = project.get_plans(is_completed: 0)
      expect(plans_without_filter.length).to be > plans_filtered.length
    end
  end

  describe 'available?' do
    it 'check availability of correct connection' do
      expect(OnlyofficeTestrailWrapper::Testrail2.new).to be_available
    end

    it 'check non-availability of correct connection' do
      OnlyofficeTestrailWrapper::Testrail2.testrail_url = 'www.ya.ru'
      expect(OnlyofficeTestrailWrapper::Testrail2.new).not_to be_available
    end
  end
end
