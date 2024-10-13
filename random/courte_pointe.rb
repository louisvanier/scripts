require 'rmagick'

@textures = {}
@textures_sizes = {
    'A': 2,
    'B': 1,
    'C': 1,
    'D': 1,
    'E': 1,
    'F': 1,
    'G': 1,
    'H': 1,
    'I': 1,
    'J': 1,
    'K': 1,
}


QUILT_WIDTH = 17
QUILT_HEIGHT = 21

@amount_each_texture = 10
@left_over = 0


def initialize_textures
    (0..QUILT_WIDTH).each do |x|
        (0..QUILT_HEIGHT).each do |y|
            @textures[x] ||= {}
            @textures[x][y] = ' '
        end
    end

    @amount_each_texture = (QUILT_HEIGHT + 1) * (QUILT_WIDTH + 1) / @textures_sizes.keys.length
    @left_over = (QUILT_HEIGHT + 1) * (QUILT_WIDTH + 1) % @textures_sizes.keys.length
end

def generate_coords
    coords = []
    (0..QUILT_WIDTH).each do |x|
        (0..QUILT_HEIGHT).each do |y|
            coords << [x, y]
        end
    end
    coords
end

def colorize(color_code, string)
    "\e[#{color_code}m#{string}\e[0m"
end

# coords is an array to support larger textures. Will check all neighbor of coords that 
# are not in coords themselves
def any_neighbor_matches_texture?(texture, coords)
    # gotta check each coords
    coords.each do |coord|
        # check +1/-1 in all directions.
        [-1, -1, 0, 1, 1].permutation(2).uniq.each do |vec_x, vec_y|
            neighbor = [coord[0] + vec_x, coord[1] + vec_y]
            # reject out of bounds
            next if neighbor[0] < 0 || neighbor[0] > QUILT_WIDTH
            next if neighbor[1] < 0 || neighbor[1] > QUILT_HEIGHT
            # reject cells already in texture
            next if coords.any? { |c| c[0] == neighbor[0] && c[1] == neighbor[1] }

            return true if @textures[neighbor[0]][neighbor[1]] == texture
        end
    end

    return false
end

def get_texture_coords(texture, starting_coords)
    length_increase = @textures_sizes.fetch(texture.to_sym, 1) - 1
    coords = [starting_coords]
    vec_x = 1
    if length_increase + starting_coords[0] > QUILT_WIDTH
        vec_x = -1
    end
    vec_y = 1
    if length_increase + starting_coords[1] > QUILT_HEIGHT
        vec_y = -1
    end

    (0..length_increase).each do |x|
        (0..length_increase).each do |y|
            next if x == 0 && y == 0 ## dont add starting point its already there
            coords << [starting_coords[0] + (x * vec_x), starting_coords[1] + (y * vec_y)]
        end
    end

    coords
end

def generate_textures
    # generate larger textures first
    generate_larger_textures

    # generate textures where size is 1 tile\
    generate_small_textures
end

def print_quilt
    # print quilt row by row
    (0..QUILT_WIDTH).each do |x|
        curr_row = []
        (0..QUILT_HEIGHT).each do |y|
            size = @textures_sizes.fetch(@textures[x][y].to_sym, 1)
            texture = @textures[x][y]
            curr_row << colorize(37 + (@textures[x][y].ord % @textures_sizes.keys.length), "#{@textures[x][y] * size}#{' ' * (3 - size)}")
        end
        puts curr_row.join(' ')
    end
end

def generate_larger_textures
    @textures_sizes.select { |texture, size| size > 1}.sort { |a,b| a[1] <=> b[1]}.reverse.each  do |texture, size|
        actual_texture_size = size * size
        (0..((@amount_each_texture / actual_texture_size) - 1)).each do |tries|
            coords = []
            loop do
                sample = @all_coords.sample
                coords = get_texture_coords(texture.to_s, sample)
                break unless any_neighbor_matches_texture?(texture.to_s, coords)
            end

            
            coords.each do |c|
                @textures[c[0]][c[1]] = texture.to_s
                @all_coords.delete(c)
            end
        end
    end
end

def generate_small_textures
    @textures_sizes.select { |texture, size| size == 1}.each do |texture, size|
        # there should be only one texture left to place, we might have ended up with
        # texture-less spaces that are clustered together. Lets separate them
        if @all_coords.length == @amount_each_texture
            print_quilt
            puts "only left space if for one texture, attempting to split empty spaces"
            split_texture(' ')
            puts " "
            puts " "
            textures_each do |t, x, y|
                next unless t == ' ' # we're only interested in the blank textyres
                @textures[x][y] = texture.to_s
            end
        else
            selected_coords ||= []
            while (selected_coords.length < @amount_each_texture)
                tentative = @all_coords.sample
                while (selected_coords.any? { |c| distance = ((c[0] - tentative[0]).abs + (c[1] - tentative[1]).abs); distance == 1}) do
                    tentative = @all_coords.sample
                end
                selected_coords << tentative
                @all_coords.delete(tentative)
            end
            selected_coords.each do |x, y|
                @textures[x][y] = texture.to_s
            end
        end
    end
end

def swap(x1, y1, x2, y2)
    temp = @textures[x2][y2]
    @textures[x2][y2] = @textures[x1][y1]
    @textures[x1][y1] = temp
end

def textures_each(x_from = 0, y_from = 0, x_to = QUILT_WIDTH, y_to = QUILT_HEIGHT)
    (x_from..x_to).each do |x|
        (y_from..y_to).each do |y|
            yield @textures[x][y], x, y
        end
    end
end

def split_texture(texture_to_split)
    puts "splitting texture: #{texture_to_split}"
    textures_each do |texture, x, y|
        next unless texture == texture_to_split
        next unless any_neighbor_matches_texture?(texture_to_split, [[x,y]]) # we dont need to split this if its already not close to a matching neighbor
        puts "found texture with neighbor at #{x}, #{y}"

        x_from = (x + 2) % 18
        x_to = (x - 2) % 18

        y_from = (y + 2) % 22
        y_to = (y - 2) % 22

        # forward x, forward y search
        found = false
        [[x_from, y_from, QUILT_WIDTH, QUILT_HEIGHT],[x_from, 0, QUILT_WIDTH, y_to],[0, y_from, x_to,QUILT_HEIGHT],[0,0,x_to, y_to]].each do |scan_coords|
            textures_each(scan_coords[0],scan_coords[1],scan_coords[2],scan_coords[3]) do |tentative_swap_texture, search_x, search_y|
                next if tentative_swap_texture == texture_to_split
                next if @textures_sizes.fetch(tentative_swap_texture.to_sym, 1) > 1
                next if any_neighbor_matches_texture?(texture_to_split,[[search_x, search_y]])
                next if any_neighbor_matches_texture?(tentative_swap_texture, [[x,y]])
                found = true
                puts "swapping #{x},#{y} -> #{search_x}, #{search_y}: #{tentative_swap_texture}"
                swap(x, y, search_x, search_y)
                break
            end
            break if found
        end
    end
end

def generate_quilt
    loop do
        initialize_textures
        @all_coords = generate_coords
        generate_textures
        break unless @textures.any? { |row, col| col.any? { |_, cell| cell == ' ' }}
        puts "there were holes in the quilt, trying again"
    end
    print_quilt
end

def generate_image_list_from_textures
    image_paths = []
    textures_each do |t, _, _|
        image_paths << "./#{t}.jpg"
    end
    return image_paths
end

def generate_image_of_quilt
    ilist = Magick::ImageList.new(*generate_image_list_from_textures)
    montage = ilist.montage { |opt| opt.tile = Magick::Geometry.new(QUILT_HEIGHT + 1, QUILT_WIDTH + 1); opt.geometry = Magick::Geometry.new(150,150); }
    montage.write('./maybe.jpg')
end

generate_quilt
generate_image_of_quilt
