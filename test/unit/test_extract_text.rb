require 'test_helper'
require 'tmpdir'

class ExtractTextTest < Test::Unit::TestCase

  FULL_TEXT = <<-EOS
BARACK OBAMA: A CHAMPION FOR ARTS AND CULTURE
Our nation’s creativity has filled the world’s libraries, museums, recital halls, movie houses, and marketplaces with works of genius. The arts embody the American spirit of self-definition. As the author of two best-selling books – Dreams from My Father and The Audacity of Hope – Barack Obama uniquely appreciates the role and value of creative expression. A PLATFORM IN SUPPORT OF THE ARTS Reinvest in Arts Education: To remain competitive in the global economy, America needs to reinvigorate the kind of creativity and innovation that has made this country great. To do so, we must nourish our children’s creative skills. In addition to giving our children the science and math skills they need to compete in the new global context, we should also encourage the ability to think creatively that comes from a meaningful arts education. Unfortunately, many school districts are cutting instructional time for art and music education. Barack Obama believes that the arts should be a central part of effective teaching and learning. The Chairman of the National Endowment for the Arts recently said “The purpose of arts education is not to produce more artists, though that is a byproduct. The real purpose of arts education is to create complete human beings capable of leading successful and productive lives in a free society.” To support greater arts education, Obama will: Expand Public/Private Partnerships Between Schools and Arts Organizations: Barack Obama will increase resources for the U.S. Department of Education’s Arts Education Model Development and Dissemination Grants, which develop public/private partnerships between schools and arts organizations. Obama will also engage the foundation and corporate community to increase support for public/private partnerships. Create an Artist Corps: Barack Obama supports the creation of an “Artists Corps” of young artists trained to work in low-income schools and their communities. Studies in Chicago have demonstrated that test scores improved faster for students enrolled in low-income schools that link arts across the curriculum than scores for students in schools lacking such programs. Publicly Champion the Importance of Arts Education: As president, Barack Obama will use the bully pulpit and the example he will set in the White House to promote the importance of arts and arts education in America. Not only is arts education indispensable for success in a rapidly changing, high skill, information economy, but studies show that arts education raises test scores in other subject areas as well. Support Increased Funding for the NEA: Over the last 15 years, government funding for the National Endowment for the Arts has been slashed from $175 million annually in 1992 to $125 million today. Barack Obama supports increased funding for the NEA, the support of which enriches schools and neighborhoods all across the nation and helps to promote the economic development of countless communities. Paid for by Obama for America
  EOS

  def test_paged_extraction
    Docsplit.extract_text('test/fixtures/obama_arts.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 2
    assert File.read("#{OUTPUT}/obama_arts_1.txt").strip == FULL_TEXT.strip
  end

  def test_page_only_extraction
    Docsplit.extract_text('test/fixtures/obama_arts.pdf', :pages => 2..2, :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"] == ["#{OUTPUT}/obama_arts_2.txt"]
  end

  def test_capitalized_pdf_extraction
    Dir["#{OUTPUT}/*.txt"].each {|previous| FileUtils.rm(previous) }
    Dir.mktmpdir do |dir|
      FileUtils.cp('test/fixtures/obama_arts.pdf', "#{dir}/OBAMA_ARTS.PDF")
      Docsplit.extract_text("#{dir}/OBAMA_ARTS.PDF", :pages => 2..2, :output => OUTPUT)
    end
    assert Dir["#{OUTPUT}/*.txt"] == ["#{OUTPUT}/OBAMA_ARTS_2.txt"]
  end

  def test_unicode_extraction
    Docsplit.extract_text('test/fixtures/unicode.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 3
  end

  def test_ocr_extraction
    Docsplit.extract_text('test/fixtures/corrosion.pdf', :pages => 'all', :output => OUTPUT)
    assert Dir["#{OUTPUT}/*.txt"].length == 4
    4.times do |i|
      file = "corrosion_#{i + 1}.txt"
      assert File.read("#{OUTPUT}/#{file}") == File.read("test/fixtures/corrosion/#{file}")
    end
  end

  def test_password_protected
    assert_raises(ExtractionFailed) do
      Docsplit.extract_text('test/fixtures/completely_encrypted.pdf')
    end
  end

end
