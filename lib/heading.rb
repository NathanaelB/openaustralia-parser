class HeadingBase
  def initialize(title, major_count, minor_count, url, date, house)
    @title, @major_count, @minor_count, @url, @date, @house = title, major_count, minor_count, url, date, house
  end
  
  def id
    if @house.representatives?
      "uk.org.publicwhip/debate/#{@date}.#{@major_count}.#{@minor_count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@major_count}.#{@minor_count}"
    end
  end
end

class MajorHeading < HeadingBase
  def output(x)
    x.tag!("major-heading", @title, :id => id, :url => @url)
  end
end

class MinorHeading < HeadingBase
  def output(x)
    x.tag!("minor-heading", @title, :id => id, :url => @url)
  end
end
