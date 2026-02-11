import { Controller, Get, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../guards/jwt.guard';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  @Get('me')
  me(@Req() req: { user: { id: string; email: string } }) {
    return { id: req.user.id, email: req.user.email };
  }
}
