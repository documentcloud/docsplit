require 'test_helper'

class RepairPagesTest < Test::Unit::TestCase

  def test_page_repair
    Docsplit.repair_pages('test/fixtures/broken.pdf', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 1
    assert File.exist?("#{OUTPUT}/broken_repaired.pdf")
  end

  def test_password_protected
    assert_raises(RepairFailed) do
      Docsplit.repair_pages('test/fixtures/completely_encrypted.pdf')
    end
  end

  def test_name_escaping_while_repairing_pages
    Docsplit.repair_pages('test/fixtures/PDF file with spaces \'single\' and "double quotes".pdf', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.pdf"].length == 1
    assert File.exist?("#{OUTPUT}" + '/PDF file with spaces \'single\' and "double quotes"_repaired.pdf')
  end

  def test_password_protected
    assert_raises(RepairFailed) do
      Docsplit.repair_pages('test/fixtures/completely_encrypted.pdf')
    end
  end

end
